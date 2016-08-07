module Pips3Api
  class Genre < Base
    attr_accessor :genre_id, :name
    attr_accessor :subgenres
    set_collection_name "genre"
    set_default_identifier_type "genre_id"
    set_xml_collection_name "genre_group"

    def parse_xml(data)
      self.subgenres = []
      data.xpath('//genre').each do |subgenre|
        self.subgenres << {
          :id => subgenre['genre_id'],
          :name => subgenre.inner_html.gsub('&amp;', '&'),
          :type => subgenre['type']
        }
      end
      self.name = subgenres.last[:name]
    end

    def build_xml(xml)
      xml.genre_group(:genre_id => genre_id, :type => 'iplayer_composite') do
        subgenres.each do |subgenre|
          xml.genre(
            subgenre[:name],
            :genre_id => subgenre[:id],
            :type => subgenre[:type]
          )
        end
      end
    end

  end
end
