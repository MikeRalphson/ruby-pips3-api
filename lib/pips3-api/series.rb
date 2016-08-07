module Pips3Api
  class Series < Programme
    attr_accessor :brand_pid, :master_brand_mid
    set_collection_name "series"
    set_default_identifier_type "pid"

    def parse_xml(data)
      self.brand_pid = data.at('member_of/link')['pid'] if data.at('member_of/link')
      self.master_brand_mid = data.at('master_brand/link')['mid'] if data.at('master_brand/link')
      self.title = data.at("title").inner_text
      data.search("synopses/synopsis").each { |element|
        self.send("synopsis_#{element['length']}=", element.inner_text)
      }

      self.genre_ids = []
      data.search("genres/genre_group").each do |genre|
        genre_ids << genre['genre_id']
      end
      self.format_id = data.at('formats/format')['format_id'] if data.at('formats/format')
      self.filename_template = inner_text_or_nil(data, 'filename_template')
    end

    def brand
      @brand ||= Brand.find(brand_pid)
    end

    def master_brand
      @master_brand ||= MasterBrand.find(master_brand_mid)
    end

    def build_xml(xml)
      if brand_pid
        xml.member_of do
          xml.link(:rel => "pips-meta:brand", :pid => brand_pid)
        end
      else
        xml.member_of
      end

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
      xml.stack
      if filename_template
        xml.filename_template(filename_template)
      else
        xml.filename_template
      end
    end

  end
end
