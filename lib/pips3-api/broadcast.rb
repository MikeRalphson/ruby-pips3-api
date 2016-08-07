module Pips3Api
  class Broadcast < Base
    attr_accessor :pid
    attr_accessor :start_time, :end_time, :duration
    attr_accessor :accurate_start, :accurate_end
    attr_accessor :live, :blanked, :repeat, :critical, :audio_described
    attr_accessor :sound_format, :aspect_ratio
    attr_accessor :pics_raw_data
    attr_accessor :version_pid, :version
    attr_accessor :episode_pid, :episode
    attr_accessor :brand_pid, :brand
    attr_accessor :service_sid, :service
    attr_accessor :contract_pid

    set_collection_name "broadcast"
    set_default_identifier_type "pid"

    def parse_xml(data)
      self.version_pid = data.at('broadcast_of/link')['pid']
      self.service_sid = data.at('broadcaster/link')['sid']

      self.live = (data.at('live')['value'] == 'true')
      self.blanked = (data.at('blanked')['value'] == 'true')
      self.repeat = (data.at('repeat')['value'] == 'true')
      self.critical = (data.at('critical')['value'] == 'true')
      
      if ad = data.at('audio_described')
        self.audio_described = (ad['value'] == 'true')
      end

      if ar = data.at('audio_visual_attributes/aspect_ratio')
        self.aspect_ratio = ar.inner_text
      end

      if sf = data.at('audio_visual_attributes/sound_format')
        self.sound_format = sf.inner_text
      end

      self.start_time = Time.parse(data.at('published_time')['start'])
      self.end_time = Time.parse(data.at('published_time')['end'])
      self.duration = data.at('published_time')['duration']
      
      if data.at('accurate_time')
        self.accurate_start = Time.parse(data.at('accurate_time')['broadcast_start'])
        self.accurate_end = Time.parse(data.at('accurate_time')['broadcast_end'])
      end
      
      if data.at('pics_raw_data')
        self.pics_raw_data = data.at('pics_raw_data').inner_text
      end

      if link = data.at('applied_contract/link')
        self.contract_pid = link['pid']
      end
    end

    def build_xml(xml)

      xml.broadcast_of do
        xml.link(:rel => "pips-meta:version", :pid => version_pid)
      end

      xml.broadcaster do
        xml.link(:rel => "pips-meta:service", :sid => service_sid)
      end

      xml.synopses

      xml.live(:value => live ? 'true' : 'false')
      xml.blanked(:value => blanked ? 'true' : 'false')
      xml.repeat(:value => repeat ? 'true' : 'false')
      xml.critical(:value => critical ? 'true' : 'false')
      
      unless audio_described.nil?
        xml.audio_described(:value => audio_described ? 'true' : 'false')
      end

      xml.audio_visual_attributes do
        xml.aspect_ratio(aspect_ratio) unless aspect_ratio.nil?
        xml.sound_format(sound_format) unless sound_format.nil?
      end

      if duration.nil?
        self.duration = (end_time - start_time).to_i
      end

      if duration.is_a?(Fixnum)
        duration_string = Time.at(duration).gmtime.strftime("%H:%M:%S")
      elsif duration.is_a?(Time)
        duration_string = duration.strftime("%H:%M:%S")
      else
        duration_string = duration.to_s
      end

      xml.published_time(
        :start => start_time.gmtime.strftime("%FT%TZ"),
        :end => end_time.gmtime.strftime("%FT%TZ"),
        :duration => duration_string
      )
      
      if accurate_start || accurate_end
        xml.accurate_time(
          :broadcast_start => iso_accurate_start,
          :broadcast_end => iso_accurate_end
        )
      end
      
      if pics_raw_data
        xml.pics_raw_data(pics_raw_data)
      end

      if contract_pid
        xml.applied_contract do
          xml.link(:rel => "pips-meta:rights_contract", :pid => contract_pid)
        end
      end

      xml.links
    end

    def version
      @version ||= Version.find(@version_pid)
    end

    def episode
      @episode ||= Episode.find(@episode_pid)
    end

    def brand
      @brand ||= Brand.find(@brand_pid)
    end

    def service
      @service ||= Service.find(@service_sid)
    end
    
    def iso_accurate_start
      iso_accurate(accurate_start)
    end
    
    def iso_accurate_end
     iso_accurate(accurate_end)
    end

    # Finds schedule from service and time query
    # @todo to patch returns 'as of type' consistent to API
    # @return <Object> Single broadcast from query.
    def self.find_at_time(service, time)
      time = Time.parse(time.to_s) if time.class != Time
      schedule = Schedule.find_by_date(service, time.strftime("%Y-%m-%d"))
      unless schedule.nil? or schedule.broadcasts.nil?
        schedule.broadcasts.each do |item|
          if (item.start_time <= time and time <= item.end_time)
            return item
          end
        end
      end
      logger.warn "#{self.class}.find_at_time: no programme found for #{service} at #{time}" unless logger.nil?
      nil
    end

    def service
      @service ||= Service.find(service_sid)
    end
    
    protected

    def iso_accurate(time)
      millisec = sprintf("%3.3d", time.usec / 1000)
      time.gmtime.strftime("%FT%T.#{millisec}Z")
    end

  end
end
