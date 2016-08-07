module Pips3Api
  class Programme < Base
    attr_accessor :pid, :title, :synopsis_short, :synopsis_medium, :synopsis_long
    attr_accessor :genre_ids, :format_id
    attr_accessor :filename_template

    def relationships(type=nil)
      query = {}
      query[:rt_id] = type unless type.nil?

      Relationship.find(
        :all,
        :from => "#{self.class.collection_name}/pid.#{pid}/relationships",
        :query => query
      )
    end

    def image
      image_relationship = relationships('is_image_for').first
      Image.find(image_relationship.subject_pid) unless image_relationship.nil?
    end

    def build_genres_and_formats_xml(xml)
      unless genre_ids.nil? or genre_ids.empty?
        xml.genres do
          genre_ids.each do |genre_id|
            genre = Pips3Api::Genre.find(genre_id)
            genre.build_xml(xml) unless genre.nil?
          end
        end
      else
        xml.genres
      end

      unless format_id.nil?
        xml.formats do
          xml.format(:format_id => format_id)
        end
      else
        xml.formats
      end
    end

  end
end
