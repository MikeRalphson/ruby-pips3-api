module Pips3Api
  class Episode < Programme
    attr_accessor :member_of_pid, :member_of_type, :brand_pid, :master_brand_mid
    attr_accessor :containers_title, :presentation_title
    attr_accessor :release_date, :release_year
    attr_accessor :language
    attr_accessor :genre_ids, :format_id
    attr_accessor :media_type
    attr_accessor :is_embeddable
    set_collection_name "episode"
    set_default_identifier_type "pid"

    def release_date=(date)
      case date
      when Date
        @release_date = date
      else
        @release_date = Date.parse(date.to_s)
      end
      @release_year = @release_date.year
    end

    def parse_xml(data)
      if link = data.at('member_of/link')
        self.member_of_pid = link['pid']
        self.member_of_type = link['rel'].sub(/pips-meta:/,'')
      end

      self.brand_pid = data.at('member_of_brand/link')['pid'] if data.at('member_of_brand/link')
      self.master_brand_mid = data.at('master_brand/link')['mid'] if data.at('master_brand/link')
      self.title = inner_text_or_nil(data, "title")
      self.containers_title = inner_text_or_nil(data, "containers_title")
      self.presentation_title = inner_text_or_nil(data, "presentation_title")

      if date = data.at('release_date') and date.has_attribute?('year')
        self.release_year = date['year'].to_i
        if date.has_attribute?('month') and date.has_attribute?('day')
          self.release_date = Date.new(
            date['year'].to_i,
            date['month'].to_i,
            date['day'].to_i
          )
        end
      end

      data.search("synopses/synopsis").each { |element|
        self.send("synopsis_#{element['length']}=", element.inner_text)
      }
      self.language = inner_text_or_nil(data, 'languages/language')
      self.media_type = data.at("media_type")['value'] if data.at('media_type')

      self.genre_ids = []
      data.search("genres/genre_group").each do |genre|
        genre_ids << genre['genre_id']
      end
      self.format_id = data.at('formats/format')['format_id'] if data.at('formats/format')

      self.filename_template = inner_text_or_nil(data, 'filename_template')
      if embeddable = data.at('is_embeddable')
        self.is_embeddable = embeddable['value'] == 'true'
      end
    end

    def brand
      @brand ||= Brand.find(brand_pid)
    end

    def master_brand
      @master_brand ||= MasterBrand.find(master_brand_mid)
    end

    def versions
      @versions ||= Version.find(:all, :from => "episode/pid.#{pid}/versions")
    end

    def build_xml(xml)
      if member_of_type and member_of_pid
        xml.member_of do
          xml.link(:rel => "pips-meta:#{member_of_type}", :pid => member_of_pid)
        end
      else
        xml.member_of
      end

      xml.member_of_brand

      if master_brand_mid
        xml.master_brand do
          xml.link(:rel => "pips-meta:master_brand", :mid => master_brand_mid)
        end
      else
        xml.master_brand
      end

      xml.title(title)
      if containers_title
        xml.containers_title(containers_title)
      else
        xml.containers_title
      end
      if presentation_title
        xml.presentation_title(presentation_title)
      else
        xml.presentation_title
      end

      if release_date
        xml.release_date(
          :year => release_date.year,
          :month => release_date.month,
          :day => release_date.day
        )
      elsif release_year
        xml.release_date(:year => release_date.year)
      else
        xml.release_date
      end

      xml.uri

      build_synopses_xml(xml)

      if language
        xml.languages do
          xml.language(language.to_s.upcase)
        end
      end

      build_genres_and_formats_xml(xml)

      xml.classifications

      if media_type
        xml.media_type(:value => media_type)
      else
        xml.media_type
      end

      if filename_template
        xml.filename_template(filename_template)
      else
        xml.filename_template
      end
      xml.origination
      xml.is_embeddable(:value => is_embeddable ? 'true' : 'false')
    end
  end
end
