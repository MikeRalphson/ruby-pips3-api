module Pips3Api
  class Tagging < Base
    attr_accessor :pid, :application_of_pid, :application_to_pid, :application_to_type
    set_collection_name "tagging"
    set_default_identifier_type "pid"

    def parse_xml(data)
      self.application_of_pid = data.at('application_of/link')['pid']
      self.application_to_pid = data.at('application_to/link')['pid']
    end
    
    def tag
      @tag ||= Tag.find(application_of_pid)
    end

    def build_xml(xml)
      application_to_type = 'clip' if application_to_type.nil?
    
      xml.application_of do
        xml.link(:rel => "pips-meta:tag", :pid => application_of_pid)
      end
      xml.application_to do
        xml.link(:rel => "pips-meta:#{application_to_type}", :pid => application_to_pid)
      end
      xml.links
    end

  end
end
