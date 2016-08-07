module Pips3Api
  class Schedule < Base
    attr_accessor :sid, :pid, :start_time, :end_time, :broadcasts
    set_collection_name "schedule"
    set_default_identifier_type "sid"

    # Finds schedule from service and temporal based query
    # @see Pips3Api::Base
    # @todo to lend more control when forming schedule specific queries
    def self.find(service, query={})
      return if service.nil?
      url = self.url_for(service, query)
      doc = request(:get, url)
      if doc.kind_of? Nokogiri::XML::Document
        self.new(doc.at("/pips/#{xml_collection_name}"))
      else
        logger.warn "#{self.class}.find: No results #{url}" unless logger.nil?
        nil
      end
    end

    # Builds URL from class callee, service and temporal based queries
    # @see Pips3Api::Base
    # @todo to patch URI un-escaping DateTime queries
    # @todo to patch PipsApi specific "timezone" formatting
    def self.url_for(service, query={})
      service = service.sid if service.kind_of? Service
      query = query.merge({:service => service}).
        sort { |a,b| a.to_s <=> b.to_s }.
        map {|k,v| "#{k.to_s}=#{v.to_s.gsub(/\+\d+:\d+$/,'Z')}"}.join('&')
      URI.parse("#{endpoint}/schedule/date/#{"?#{query}" unless query.empty?}")
    end

    # Finds schedule from service and date query
    # @todo to patch URI un-escaping DateTime queries
    # @todo to patch returns 'as of type' consistent to API
    # @return <Object> Schedule list for broadcast or broadcasts from query.
    def self.find_by_date(service, date)
      date = Date.parse(date.to_s)
      self.find(service, {:start => "#{date-1}T23:00:00Z", :end => "#{date+1}T00:00:00Z"}) unless date.nil?
    end

    def service
      @service ||= Service.find(sid)
    end

    # Parses API response XML and sorts results
    # @see Pips3Api::Base
    # @see https://confluence.dev.bbc.co.uk/display/pips/Sanitising+the+Schedule+API
    # @todo to patch properties which fall between API collections and resource serialisation.
    # @todo to patch unsorted items for more predictable (test!) results.
    def parse_xml(data)

      self.broadcasts ||= []

      service = data.at('//service')
      coverage = data.at('//covers')

      # @todo to format in-line with API/VCS2MQ conventions
      self.start_time = Time.parse(coverage['start'])
      self.end_time = Time.parse(coverage['end'])

      data.search("item/broadcast").each do |node|
        pid = node['pid']
        if defined?(pid)
          broadcast = Broadcast.new(node)
          broadcast.brand = extract_sibling(:brand, node)
          broadcast.episode = extract_sibling(:episode, node)
          broadcast.version = extract_sibling(:version, node)
          self.broadcasts << broadcast
        end
      end

      return if service.nil?

      self.sid = service['sid']
      self.pid = service.at('ids/id').inner_text
      self.last_modified_supplier = service['last_modified_supplier']
      self.revision = service['revision'].to_i
      self.broadcasts.sort_by { |b| b.start_time } unless self.broadcasts.empty?
    end

    private

    # Extracts XML siblings by key, relative to schedule broadcast
    # @return <Object> Class object of type key, Can return nil.
    def extract_sibling(key, node)
      return if node.nil?

      node = node.parent.at(key)
      case key
      when :brand then Brand.new(node)
      when :episode then Episode.new(node)
      when :version then Version.new(node)
      else
        logger.warn "#{self.class} extract_sibling: No results #{node.name} #{key}" unless logger.nil?
      end
    end
  end
end
