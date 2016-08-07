require 'rubygems'
require 'nokogiri'
require 'builder'
require 'net/https'
require 'time'
require 'cgi'
require 'pp'
require 'date'
require 'time'

module Pips3Api
  class Base
    attr_accessor :revision, :last_modified, :last_modified_supplier, :ids, :type
    attr_accessor :supplier_user, :supplier_group

    class << self
      attr_accessor :collection_name
      attr_accessor :xml_collection_name
      attr_accessor :default_identifier_type
      attr_accessor :config
      attr_accessor :logger
      attr_accessor :timeout
      attr_accessor :attributes

      alias_method :set_collection_name, :collection_name=
      alias_method :set_xml_collection_name, :xml_collection_name=
      alias_method :set_default_identifier_type, :default_identifier_type=

      def xml_collection_name
        @xml_collection_name || @collection_name
      end

      def config
        if defined?(@config)
          @config
        elsif superclass != Object && superclass.config
          superclass.config.dup.freeze
        end
      end

      def endpoint
        URI.parse(config[:endpoint].to_s)
      end

      def logger
        if defined?(@logger)
          @logger
        elsif superclass != Object && superclass.logger
          superclass.logger.dup.freeze
        end
      end

      def cache
        @cache ||= Cache.new(config[:cache_dir]) if config[:cache_dir]
      end

      def timeout
        @timeout ||= 30
      end

      def find(key, params={})
        return nil if key.nil?
        query = params[:query] || {}

        if (key == :all)
          results, page = [], nil
          collection = params[:from] || collection_name
          while collection
            query[:page] = page if page
            url = url_for(:collection => collection, :query => query)
            doc = request(:get, url)
            unless doc.nil?
              elements = doc.xpath("//results/*").select { |e| e.kind_of? Nokogiri::XML::Element }
              results += elements.map { |e| self.new(e) }
              link = doc.xpath("//links/link").detect { |l| l['rel'] == 'pips-meta:pager-next' }
              page = (link and link['href'] =~ /page=(\d+)/) ? $1 : nil
            end
            collection = nil unless page
            break if params[:recurse] === false
          end
          results
        else
          url = url_for(params.merge(:resource => key, :query => query))
          doc = request(:get, url)
          self.new( doc.at("/pips/#{xml_collection_name}") ) unless doc.nil?
        end
      end

      def count(params={})
        query = params[:query] || {:rows => 1}
        collection = params[:from] || collection_name
        url = url_for(:collection => collection, :query => query)
        doc = request(:get, url)
        results = doc.at("/pips/results")
        results['total'].to_i unless results.nil?
      end

      def url_for(options={})
        if options.has_key? :resource
          resource = options[:resource]

          if options[:resource].kind_of? Hash
            identifier_type, resource = resource.keys.first, resource.values.first
          elsif options.has_key? :identifier_type
            identifier_type = options[:identifier_type]
          else
            identifier_type = default_identifier_type
          end
          path = "#{collection_name}/#{identifier_type}.#{resource}"
        elsif options.has_key? :collection
          path = options[:collection]
        else
          raise "unable to process option passed to url_for"
        end

        query = options[:query] || {}
        query = query.map{|k,v| "#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}"}.join('&')

        # Build up the URI
        uri = endpoint.dup
        uri.path += '/' unless uri.path[-1,1] == '/'
        uri.path += path + '/'
        uri.query = query unless query.empty?
        uri.user = nil
        uri.password = nil

        uri
      end

      # Builds HTTP connection object from URL
      def build_connection(url)

        if config[:proxy]
          proxy = URI.parse(config[:proxy])
          http = Net::HTTP::Proxy(proxy.host, proxy.port).new(url.host, url.port)
        else
          http = Net::HTTP.new(url.host, url.port)
        end

        http.set_debug_output($stderr) if config[:debug]

        if url.scheme == "https"
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        if config[:certificate_path]
          cert = File.read(config[:certificate_path])
          http.key = OpenSSL::PKey::RSA.new(cert)
          http.cert = OpenSSL::X509::Certificate.new(cert)
        end

        http
      end

      def request(method, url, body=nil)
        if method == :get and self.cache
          self.cache.fetch(url) do
            perform_request(method, url, body)
          end
        else
          perform_request(method, url, body)
        end
      end

      def perform_request(method, url, body=nil)
        url = url_for(url) unless url.is_a?(URI)

        connection = build_connection(url)
        response = connection.start do |http|

          http.open_timeout = timeout
          http.read_timeout = timeout

          uri = url.request_uri

          logger.info "Pips3Api #{method.to_s.upcase} - #{url}" if logger
          logger.debug "Pips3Api #{method.to_s.upcase} request body:\n #{body}" if logger and body

          request = case method.to_sym
            when :get then Net::HTTP::Get.new(uri)
            when :post then Net::HTTP::Post.new(uri)
            when :put then Net::HTTP::Put.new(uri)
            when :delete then Net::HTTP::Delete.new(uri)
            else raise "Unsupported request method #{method}"
          end

          request.basic_auth(endpoint.user, endpoint.password) if endpoint.user || endpoint.password
          request.set_content_type('application/xml')
          request.add_field("User-Agent", "Pips3Api Ruby Gem")
          #request.add_field("X-PIPs-User", supplier_user) unless supplier_user.nil?
          #request.add_field("X-PIPs-Group", supplier_group) unless supplier_group.nil?
          request.add_field("Connection", "Close")
          http.request(request, body)
        end

        logger.debug "Pips3Api #{method.to_s.upcase} response #{response.code}:\n #{response.body}" if logger
        raise "Unauthorised request" if response.is_a? Net::HTTPUnauthorized

        # Raise error if response wasn't success
        if response.is_a? Net::HTTPSuccess and response.content_type == 'application/xml'
          doc = Nokogiri::XML(response.body)
          if doc.instance_of? Nokogiri::XML::Document
            doc.remove_namespaces!
            return doc
          else
            raise "Failed to parse XML: #{e.message}"
          end
        else
          unless response.code.to_i == 404
            logger.warn "Pips3Api request failed: #{method.to_s.upcase} #{url} (#{response.code})"
            logger.debug "Pips3Api response:\n #{response.body}"
          end
          nil
        end
      end
    end

    def initialize(data={})
      self.ids = {}
      if data.is_a?(Hash)
        data.each_pair do |key,value|
          self.send("#{key}=", value)
        end
      elsif data.is_a?(String)
        self.identifier = data
      elsif data.kind_of?(Nokogiri::XML::Element)
        from_xml(data)
      end

      @initial_attributes = attributes
    end

    def logger
      self.class.logger
    end

    def identifier
      if self.class.default_identifier_type
        self.send(self.class.default_identifier_type)
      end
    end

    def identifier=(value)
      if self.class.default_identifier_type
        self.send("#{self.class.default_identifier_type}=", value)
      end
    end

    def inspect
      "#<#{self.class.to_s}:#{identifier}>"
    end

    ATTRIBUTES_TO_IGNORE = [:last_modified_supplier, :last_modified, :revision, :initial_attributes]
    def attributes
      obj = {}
      self.instance_variables.each do |name|
        key = name.to_s.gsub("@","").to_sym

        unless ATTRIBUTES_TO_IGNORE.include?(key)
          value = self.instance_variable_get(name)
          if value.is_a?(Hash)
            obj[key] = value.clone
          else
            obj[key] = value
          end
        end
      end
      obj
    end

    def pips_url
      self.class.url_for(:resource => identifier) unless identifier.nil?
    end

    def from_xml(data, full_parse=true)
      klass = self.class
      if data.name != klass.xml_collection_name
        raise "Error constructing a #{klass.to_s} from a #{data.name} element"
      end

      self.identifier = data[klass.default_identifier_type]
      self.revision = data['revision'].to_i
      self.type = data['type'] if data.has_attribute?('type')
      self.last_modified = Time.parse(data['last_modified']) if data.has_attribute?('last_modified')
      self.last_modified_supplier = data['last_modified_supplier']
      self.supplier_user = data['supplier_user'] if data.has_attribute?('supplier_user')
      self.supplier_group = data['supplier_group'] if data.has_attribute?('supplier_group')

      data.search("ids/id").each { |element|
        self.ids["#{element['authority']}-#{element['type']}"] = element.inner_text
      }

      parse_xml(data) if full_parse
    end

    def inner_text_or_nil(data, path)
      node = data.at(path)
      # TODO this was breaking some tests, why?
      # node.inner_text if node and node.children
      node.inner_text unless node.nil? or node.inner_text.nil? or node.inner_text.empty?
    end

    def build_synopses_xml(xml)
      if synopsis_short || synopsis_medium || synopsis_long
        xml.synopses do
          xml.synopsis(synopsis_short, :length => 'short') if synopsis_short
          xml.synopsis(synopsis_medium, :length => 'medium') if synopsis_medium
          xml.synopsis(synopsis_long, :length => 'long') if synopsis_long
        end
      else
        xml.synopses
      end
    end

    def to_xml
      attributes = {}
      unless identifier.nil?
        attributes[self.class.default_identifier_type] = identifier
        attributes['href'] = pips_url
      end
      attributes['revision'] = revision unless revision.nil?
      attributes['type'] = type unless type.nil?

      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.instruct!
      xml.pips('xmlns'           => 'http://ns.webservices.bbc.co.uk/2006/02/pips',
               'xmlns:pips-meta' => 'http://ns.webservices.bbc.co.uk/2006/02/pips-meta',
               'xmlns:xsd'       => 'http://www.w3.org/2001/XMLSchema-datatypes') do
        xml.tag!(self.class.xml_collection_name, attributes) do
          if ids.empty?
            xml.ids
          else
            xml.ids do
              ids.each_pair do |key,value|
                authority, type = key.split('-')
                xml.id(value, :authority => authority, :type => type) unless value.nil?
              end
            end
          end
          build_xml(xml)
        end
      end
    end

    def new_record?
      identifier.nil?
    end

    def save!
      if new_record?
        create!
      else
        update!
      end
    end

    def create!
      doc = self.class.request(:post, {:collection => self.class.collection_name}, self.to_xml)
      unless doc.nil?
        new_data = doc.at("change/differences/after/#{self.class.xml_collection_name}")
        from_xml(new_data, full_parse=false) unless new_data.nil?
        doc.at("errors").children.empty?
      end
    end

    def update!
      if changed?
        logger.debug("Changes to #{self.identifier}: #{self.changes.inspect}")
        doc = self.class.request(:put, {:resource => self.identifier}, self.to_xml)
        if doc
          doc.at("errors").children.empty?
        end
      else
        logger.info("#{self.class.to_s} not changed, not updating pips: #{self.identifier}")
        true
      end
    end

    def delete!
      self.class.request(:delete, {:resource => self.identifier})
    end

    def changed?
      @initial_attributes != attributes
    end

    def changes
      before, after = @initial_attributes, attributes
      after.keys.inject({}) do |memo, key|
        unless after[key] == before[key]
          memo[key] = [after[key], before[key]]
        end
        memo
      end
    end
  end
end
