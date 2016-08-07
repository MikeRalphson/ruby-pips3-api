module Pips3Api
  class Brand < Programme
    attr_accessor :master_brand_mid
    set_collection_name "brand"
    set_default_identifier_type "pid"

    def parse_xml(data)
      self.title = data.at("title").inner_text
      data.search("synopses/synopsis").each { |element|
        self.send("synopsis_#{element['length']}=", element.inner_text)
      }
      self.master_brand_mid = data.at('master_brand/link')['mid'] if data.at('master_brand/link')

      self.genre_ids = []
      data.search("genres/genre_group").each do |genre|
        genre_ids << genre['genre_id']
      end
      self.format_id = data.at('formats/format')['format_id'] if data.at('formats/format')
      self.filename_template = inner_text_or_nil(data, 'filename_template')
    end
    
    def master_brand
      @master_brand ||= MasterBrand.find(master_brand_mid)
    end
 
     def build_xml(xml)
      if master_brand_mid
        xml.master_brand do
          xml.link(:rel => "pips-meta:master_brand", :mid => master_brand_mid)
        end
      else
        xml.master_brand
      end

      xml.title(title)

      build_synopses_xml(xml)
      build_genres_and_formats_xml(xml)

      xml.classifications
      if filename_template
        xml.filename_template(filename_template)
      else
        xml.filename_template
      end
    end
   
  end
end
