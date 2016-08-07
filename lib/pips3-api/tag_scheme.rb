module Pips3Api
  class TagScheme < Base
    attr_accessor :pid, :name, :namespace, :description
    set_collection_name "tag_scheme"
    set_default_identifier_type "pid"

    def parse_xml(data)
      self.name = data.at("name").inner_text
      self.namespace = data.at("namespace").inner_text
      self.description = data.at("description").inner_text
    end
    
    def self.find_by_namespace(value)
      tags = find(:all, :query => {:tag_scheme_namespace => value})
      tags.empty? ? nil : tags.first
    end

  end
end
