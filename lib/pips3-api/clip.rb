module Pips3Api
  class Clip < Base
    attr_accessor :pid, :title, :synopsis_short, :synopsis_medium, :synopsis_long
    attr_accessor :media_type, :brand_pid, :master_brand_mid, :genres
    set_collection_name "clip"
    set_default_identifier_type "pid"

    def parse_xml(data)
      self.title = data.at("title").inner_text
      data.search("synopses/synopsis").each { |element|
        self.send("synopsis_#{element['length']}=", element.inner_text)
      }
      self.media_type = data.at("media_type")['value'] if data.at('media_type')
      self.brand_pid = data.at('member_of_brand/link')['pid'] if data.at('member_of_brand/link')
      self.master_brand_mid = data.at('master_brand/link')['mid'] if data.at('master_brand/link')
      
      self.genres ||= []
      data.search("genres/genre_group").each { |genre| self.genres << Genre.new(genre) }
    end
    
    #def clip_of
    #  # FIXME: implement this
    #end
    
    def brand
      @brand ||= Brand.find(brand_pid)
    end
    
    def master_brand
      @master_brand ||= MasterBrand.find(master_brand_mid)
    end
    
    def versions
      @versions ||= Version.find(:all, :from => "clip/pid.#{pid}/versions")
    end

    def taggings
      @taggings ||= Tagging.find(:all, :from => "clip/pid.#{pid}/taggings")
    end

    def relationships
      @relationships ||= Relationship.find(:all, :from => "clip/pid.#{pid}/relationships")
    end
  end
end
