module Pips3Api
  class Ondemand < Base
    attr_accessor :pid
    attr_accessor :broadcast_of_pid
    attr_accessor :broadcaster_sid
    attr_accessor :duration
    attr_accessor :availability_start, :availability_end
    attr_accessor :payment_type   # free
    attr_accessor :territories    # uk / nonuk

    set_collection_name "ondemand"
    set_default_identifier_type "pid"

    def self.find_all_by_version_pid(version_pid)
      self.find(:all, :from => "version/pid.#{version_pid}/ondemands", :query => { "rows" => 50 })
    end

    def parse_xml(data)
      if link = data.at('broadcast_of/link')
        self.broadcast_of_pid = link['pid']
      end
      if link = data.at('broadcaster/link')
        self.broadcaster_sid = link['sid']
      end

      self.duration = data.at('time')['duration']
      start_str = data.at('availability')['start']
      end_str = data.at('availability')['end']
      self.availability_start = start_str.nil? ? nil : Time.parse(start_str)
      self.availability_end = end_str.nil? ? nil : Time.parse(end_str)
      self.payment_type = data.at('payment_type')['value']

      self.territories = []
      data.search('territories/territory').each do |territory|
        self.territories << territory['id'].to_sym
      end
    end

    def version
      @version ||= Version.find(broadcast_of_pid)
    end

    def service
      @service ||= Service.find(broadcaster_sid)
    end


    def build_xml(xml)
      xml.broadcast_of do
        xml.link(:rel => "pips-meta:version", :pid => broadcast_of_pid)
      end

      xml.broadcaster do
        xml.link(:rel => "pips-meta:service", :sid => broadcaster_sid)
      end

      xml.synopses

      xml.time(:duration => duration)

      if availability_end.nil?
        xml.availability(:start => availability_start)
      else
        xml.availability(:start => availability_start, :end => availability_end)
      end

      xml.payment_type(:value => payment_type)
      
      xml.playable
      xml.subtitles
      xml.filepath
      xml.filesize

      xml.territories do
        territories.each do |territory|
          xml.territory(:id => territory)
        end
      end
      
      xml.media_asset
      
      xml.links
    end

  end
end
