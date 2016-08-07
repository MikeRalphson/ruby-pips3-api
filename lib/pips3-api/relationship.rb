module Pips3Api
  class Relationship < Base
    attr_accessor :pid, :relationship_type_pid
    attr_accessor :subject_type, :subject_pid
    attr_accessor :object_type, :object_pid

    set_collection_name "relationship"
    set_default_identifier_type "pid"

    def parse_xml(data)
      self.subject_pid = data.at('subject/link')['pid']
      if rel = data.at('subject/link')['rel']
        self.subject_type = rel.split(':').last
      end

      self.relationship_type_pid = data.at('relationship_type/link')['pid']

      self.object_pid = data.at('object/link')['pid']
      if rel = data.at('object/link')['rel']
        self.object_type = rel.split(':').last
      end
    end

    def relationship_type
      @relationship_type ||= RelationshipType.find(relationship_type_pid)
    end

    def relationship_type=(rt)
      @relationship_type = rt
      @relationship_type_pid = rt.pid
    end

    def build_xml(xml)
      xml.subject do
        xml.link(:rel => "pips-meta:#{subject_type}", :pid => subject_pid)
      end
      xml.relationship_type do
        xml.link(:rel => "pips-meta:relationship_type", :pid => relationship_type_pid)
      end
      xml.object do
        xml.link(:rel => "pips-meta:#{object_type}", :pid => object_pid)
      end
    end

  end
end
