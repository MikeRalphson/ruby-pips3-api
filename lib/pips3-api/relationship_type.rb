module Pips3Api
  class RelationshipType < Base
    attr_accessor :pid, :title, :description

    set_collection_name "relationship_type"
    set_default_identifier_type "pid"

    def parse_xml(data)
      self.title = data.at("title").inner_text
      self.description = data.at("description").inner_text
    end
    
    def to_s
      title
    end
  end
end
