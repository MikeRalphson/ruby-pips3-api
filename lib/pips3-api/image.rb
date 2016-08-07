module Pips3Api
  class Image < Base
    attr_accessor :pid, :title, :image_type, :synopsis_short, :synopsis_medium, :synopsis_long
    attr_accessor :author, :shoot_date
    attr_accessor :source_width, :source_height, :source_bytes, :source_mime_type, :source_uri
    attr_accessor :focus_x, :focus_y

    set_collection_name "image"
    set_default_identifier_type "pid"

    def parse_xml(data)
      self.title = inner_text_or_nil(data, 'title')

      data.search("synopses/synopsis").each { |element|
        self.send("synopsis_#{element['length']}=", element.inner_text)
      }

      self.author = inner_text_or_nil(data, 'author')
      self.shoot_date = inner_text_or_nil(data, 'shoot_date')

      dimensions = data.at('source_asset/dimensions')
      unless dimensions.nil?
        self.source_width = dimensions['width'] ? dimensions['width'].to_i : nil
        self.source_height = dimensions['height'] ? dimensions['height'].to_i : nil
      end

      bytes = inner_text_or_nil(data, 'source_asset/size')
      self.source_bytes = bytes.to_i unless bytes.nil?

      self.source_mime_type = inner_text_or_nil(data, 'source_asset/mime_type')
      self.source_uri = inner_text_or_nil(data, 'source_asset/uri')

      focus_point = data.at('source_asset/focus_point')
      unless focus_point.nil?
        self.focus_x = focus_point['x'] ? focus_point['x'].to_i : nil
        self.focus_y = focus_point['y'] ? focus_point['y'].to_i : nil
      end

     self.image_type = inner_text_or_nil(data, 'type')

    end

    def build_xml(xml)
      xml.title(title)

      if synopsis_short || synopsis_medium || synopsis_long
        xml.synopses do
          xml.synopsis(synopsis_short, :length => 'short') if synopsis_short
          xml.synopsis(synopsis_medium, :length => 'medium') if synopsis_medium
          xml.synopsis(synopsis_long, :length => 'long') if synopsis_long
        end
      else
        xml.synopses
      end

      unless author.nil?
        xml.author(author)
      end

      xml.shoot_date(shoot_date)

      xml.source_asset do
        unless source_width.nil? and source_height.nil?
          xml.dimensions(:width => source_width, :height => source_height)
        else
          xml.dimensions
        end

        if source_bytes
          xml.size(source_bytes, :units => 'bytes')
        else
          xml.size
        end

        unless focus_x.nil? and focus_y.nil?
          xml.focus_point(:x => focus_x, :y => focus_y)
        else
          xml.focus_point
        end

        xml.mime_type(source_mime_type)
        xml.uri(source_uri)
      end

      xml.type(image_type) unless image_type.nil?
    end

    def promotions
      @promotions ||= Promotion.find(:all, :from => "image/pid.#{pid}/promotions")
    end

  end
end
