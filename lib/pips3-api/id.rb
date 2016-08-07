module Pips3Api
  class Id < Base

    class << self

      def find_by_id(id)
        ids = find_all_by_id(id)
        ids.nil? ? nil : ids.first
      end

      def find_all_by_id(id)
        return if id.nil?

        url = url_for(:collection => 'id', :query => {:id => id})
        doc = request(:get, url)
        unless doc.nil?
          doc.xpath("//results/*").select { |e| e.kind_of? Nokogiri::XML::Element }.map do |element|
            case element.name
              when "brand" then Brand.new(element)
              when "contributor" then Contributor.new(element)
              when "clip" then Clip.new(element)
              when "episode" then Episode.new(element)
              when "series" then Series.new(element)
              when "segment" then Segment.new(element)
              when "tag" then Tag.new(element)
              when "tagging" then Tagging.new(element)
              when "version" then Version.new(element)
              else raise "Unable to contruct object from #{element.name}"
            end
          end
        end
      end

    end
  end
end
