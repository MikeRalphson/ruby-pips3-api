module Pips3Api
  class Promotion < Base
    attr_accessor :pid
    attr_accessor :promotion_of_pid, :promotion_of_type
    attr_accessor :title, :synopsis_short, :synopsis_medium, :synopsis_long
    attr_accessor :uri, :by, :promoted_for
    attr_accessor :status, :start_time, :end_time
    attr_accessor :weighting
    attr_accessor :context_type, :context_pid, :cascades_to_descendants
    
    set_collection_name "promotion"
    set_default_identifier_type "pid"
    
    def parse_xml(data)
      self.promotion_of_pid = data.at('promotion_of/link')['pid']
      self.promotion_of_type = data.at('promotion_of/link')['rel'].sub('pips-meta:', '')
      self.title = data.at('title').inner_text
      data.search("synopses/synopsis").each { |element|
        self.send("synopsis_#{element['length']}=", element.inner_text)
      }
      self.uri = data.at('uri').inner_text
      self.by = data.at('by').inner_text
      self.promoted_for = data.at('for').inner_text
      if data.at('context/link')
        self.cascades_to_descendants = data.at('context')['cascades_to_descendants']
        self.context_pid = data.at('context/link')['pid']
        self.context_type = data.at('context/link')['rel'].sub('pips-meta:', '')
      end
      self.status = data.at('availability')['status']
      self.start_time = Time.parse(data.at('availability')['start'])
      self.end_time = Time.parse(data.at('availability')['end'])
      self.weighting = data.at('weighting').inner_text.to_i
    end

    def build_xml(xml)
      xml.promotion_of do
        xml.link(:rel => "pips-meta:#{promotion_of_type}", :pid => promotion_of_pid)
      end
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
      xml.uri(uri)
      xml.by(by)
      xml.for(promoted_for)
      if context_pid
        xml.context(:cascades_to_descendants => cascades_to_descendants) do
          xml.link(:rel => "pips-meta:#{context_type}", :pid => context_pid)
        end
      else
        xml.context
      end
      xml.availability(
        :status => status || 'active',
        :start => start_time.iso8601,
        :end => end_time.iso8601
      )
      xml.weighting(weighting)
    end

  end
end
