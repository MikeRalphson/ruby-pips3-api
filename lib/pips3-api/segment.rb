module Pips3Api
  class Segment < Base
    attr_accessor :pid, :duration, :title
    attr_accessor :release_title, :source_media, :catalogue_number, :record_label
    attr_accessor :publisher, :music_code, :track_number, :track_side, :recording_date
    attr_accessor :synopsis_short, :synopsis_medium, :synopsis_long
    attr_accessor :snippet_url
    set_collection_name "segment"
    set_default_identifier_type "pid"

    def parse_xml(data)
      self.duration = data.at('duration').inner_text.to_i if data.at('duration').inner_text =~ /[\d\.]+/
      self.title = inner_text_or_nil(data, 'title')

      self.release_title = inner_text_or_nil(data, 'music/release_title')
      self.source_media = inner_text_or_nil(data, 'music/source_media')
      self.catalogue_number = inner_text_or_nil(data, 'music/catalogue_number')
      self.record_label = inner_text_or_nil(data, 'music/record_label')
      self.publisher = inner_text_or_nil(data, 'music/publisher')
      self.music_code = inner_text_or_nil(data, 'music/music_code')
      self.track_number = inner_text_or_nil(data, 'music/track_number')
      self.track_side = inner_text_or_nil(data, 'music/track_side')
      self.recording_date = inner_text_or_nil(data, 'music/recording_date')

      data.search("synopses/synopsis").each { |element|
        self.send("synopsis_#{element['length']}=", element.inner_text)
      }

      self.snippet_url = inner_text_or_nil(data, 'snippet_url')
    end

    def build_xml(xml)
      xml.duration(duration)
      xml.title(title)

      if release_title || source_media || catalogue_number || record_label ||
         publisher || music_code || track_number || track_side || recording_date
        xml.music do
          element_unless_blank(xml, :release_title)
          element_unless_blank(xml, :source_media)
          element_unless_blank(xml, :catalogue_number)
          element_unless_blank(xml, :record_label)
          element_unless_blank(xml, :publisher)
          element_unless_blank(xml, :music_code)
          element_unless_blank(xml, :track_number)
          element_unless_blank(xml, :track_side)
          element_unless_blank(xml, :recording_date)
        end
      else
        xml.music
      end

      if synopsis_short || synopsis_medium || synopsis_long
        xml.synopses do
          xml.synopsis(synopsis_short, :length => 'short') if synopsis_short
          xml.synopsis(synopsis_medium, :length => 'medium') if synopsis_medium
          xml.synopsis(synopsis_long, :length => 'long') if synopsis_long
        end
      else
        xml.synopses
      end

      if snippet_url
        xml.snippet_url(snippet_url)
      else
        xml.snippet_url
      end

      xml.links
    end

    def segment_events
      @segment_events ||= SegmentEvent.find(:all, :from => "segment/pid.#{pid}/segment_events")
    end

    def contributions
      @contributions ||= Contribution.find_all_by_segment(self)
    end

    def contributions=(contributions)
      @contributions = contributions
    end

    def duration=(duration)
      @duration = duration.nil? ? nil : duration.round.to_i
    end

    private

    def element_unless_blank(xml, name)
      value = attributes[name].to_s
      unless value.nil? or value.empty?
        xml.tag!(name, value)
      end
    end
  end
end
