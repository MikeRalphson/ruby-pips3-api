module Pips3Api
  class Collection < Base
    attr_accessor :pid, :title, :url_key, :synopsis_short, :synopsis_medium, :synopsis_long
    set_collection_name "collection"
    set_default_identifier_type "pid"

    def parse_xml(data)
      self.title = data.at("title").inner_text
      self.url_key = data.at("url_key").inner_text if data.at('url_key')
      data.search("synopses/synopsis").each { |element|
        self.send("synopsis_#{element['length']}=", element.inner_text)
      }
    end

    def memberships
      @memberships ||= Membership.find(:all, :from => "collection/pid.#{pid}/group_of", :query => {:rows => 100})
    end
  end
end
