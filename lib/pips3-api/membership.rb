module Pips3Api
  class Membership < Base
    attr_accessor :pid, :member_pid, :group_pid, :position
    set_collection_name "membership"
    set_default_identifier_type "pid"

    def parse_xml(data)
      self.group_pid = data.at('group/link')['pid']
      self.member_pid = data.at('member/link')['pid']
      self.position = data.at("position").inner_text
    end
    
    def clip
      @clip ||= Clip.find(member_pid)
    end
    
    def collection
      @collection ||= Collection.find(group_pid)
    end

    def build_xml(xml)
      xml.group do
        xml.link(:rel => "pips-meta:collection", :pid => group_pid, :href => Collection.url_for(:resource => group_pid))
      end
      xml.member do
        xml.link(:rel => "pips-meta:clip", :pid => member_pid, :href => Clip.url_for(:resource => member_pid))
      end
      xml.position(position.to_i)
      xml.links
    end

  end
end
