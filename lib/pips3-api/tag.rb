module Pips3Api
  class Tag < Base
    attr_accessor :pid, :name, :value, :scheme_pid
    set_collection_name "tag"
    set_default_identifier_type "pid"

    def parse_xml(data)
      self.name = data.at("name").inner_text
      self.value = data.at("value").inner_text
      self.scheme_pid = data.at('belongs_to/link')['pid']
    end
    
    def scheme
      @scheme ||= TagScheme.find(scheme_pid)
    end
    
    def self.find_by_value(value)
      tags = find(:all, :query => {:tag_value => value})
      tags.empty? ? nil : tags.first
    end
    
    def self.find_or_create_by_value(value, options={})
      tag = find_by_value(value)
      if tag.nil?
        tag = Tag.new(options.merge(:value => value))
        tag.save!
      end
      return tag
    end

    def build_xml(xml)
      xml.belongs_to do
        xml.link(:rel => 'pips-meta:tag_scheme', :pid => scheme_pid, :href => TagScheme.url_for(:resource => scheme_pid))
      end
      xml.name(name)
      xml.value(value)
      xml.links
    end

  end
end
