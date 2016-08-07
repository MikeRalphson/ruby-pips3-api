module Pips3Api
  class SegmentEvent < Base
    attr_accessor :pid, :chapter_point, :offset, :position, :title
    attr_accessor :synopsis_short, :synopsis_medium, :synopsis_long
    attr_accessor :version_pid, :segment_pid
    set_collection_name "segment_event"
    set_default_identifier_type "pid"

    def self.find_all_by_version(version)
      SegmentEvent.find(:all, :from => "version/pid.#{version.pid}/segment_events", :query => { "rows" => 50 })
    end

    def parse_xml(data)
      self.offset = data.at('offset').inner_text.to_i if data.at('offset').inner_text =~ /[\d\.]+/
      self.position = data.at('position').inner_text.to_i if data.at('position').inner_text =~ /[\d\.]+/
      self.title = data.at('title').inner_text
      self.chapter_point = data.at('chapter_point')['value'] == 'true'
      data.search("synopses/synopsis").each { |element|
        self.send("synopsis_#{element['length']}=", element.inner_text)
      }
      self.version_pid = data.at('event_in/link')['pid']
      self.segment_pid = data.at('event_of/link')['pid']
    end

    def build_xml(xml)
      xml.event_in do
        xml.link(:rel => "pips-meta:version", :pid => version_pid)
      end
      xml.event_of do
        xml.link(:rel => "pips-meta:segment", :pid => segment_pid)
      end

      xml.chapter_point(:value => (chapter_point ? true : false))
      xml.offset(offset)
      xml.position(position)
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

      xml.links
    end

    def segment
      @segment ||= Segment.find( segment_pid )
    end

    def version
      @version ||= Version.find( version_pid )
    end

    def chapter?
      @chapter_point
    end
  end
end
