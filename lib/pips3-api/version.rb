module Pips3Api
  class Version < Base
    attr_accessor :pid
    attr_accessor :member_of_brand_pid
    attr_accessor :version_of_pid, :version_of_type
    attr_accessor :master_brand_id
    attr_accessor :version_reason, :version_type_id
    attr_accessor :language
    attr_accessor :duration
    attr_accessor :subtitles
    attr_accessor :genres, :formats
    attr_accessor :warnings, :competition_warning
    attr_accessor :credits 
    attr_accessor :sound_format, :aspect_ratio
    attr_accessor :source_asset, :filename_template

    set_collection_name "version"
    set_default_identifier_type "pid"

    def parse_xml(data)
      if link = data.at('member_of_brand/link')
        self.member_of_brand_pid = link['pid']
      end
      if link = data.at('version_of/link')
        self.version_of_pid = link['pid']
        self.version_of_type = link['rel'].split(':').last
      end
      # FIXME: master_brand
      self.version_reason = inner_text_or_nil(data, 'version_types/version_reason')
      self.version_type_id = data.at('version_types/version_type')['version_type_id']
      self.language = inner_text_or_nil(data, 'languages/language')
      self.duration = inner_text_or_nil(data, 'duration')
      # FIXME: subtitles
      # FIXME: genres
      # FIXME: formats
      # FIXME: warnings
      if comp = data.at('competition_warning')
        self.competition_warning = comp['value'] == 'true'
      end
      # FIXME: credits
      self.sound_format = inner_text_or_nil(data, 'audio_visual_attributes/sound_format')
      self.aspect_ratio = inner_text_or_nil(data, 'audio_visual_attributes/aspect_ratio')
    end

    def broadcasts
      @broadcasts ||= Broadcast.find(:all, :from => "version/pid.#{pid}/broadcasts")
    end

    def episode
      if version_of_type == 'episode'
        @episode ||= Episode.find(version_of_pid)
      end
    end

    def episode_pid
      return version_of_pid if version_of_type == 'episode'
    end

    def segment_events
      @segment_events ||= SegmentEvent.find_all_by_version(self)
    end
    
    def media_assets
      @media_assets ||= MediaAsset.find_all_by_version_pid(pid)
    end
    
    def ondemands
      @ondemands ||= Ondemand.find_all_by_version_pid(pid)
    end


    def build_xml(xml)
      unless member_of_brand_pid.nil?
        xml.member_of_brand do
          xml.link(:rel => "pips-meta:brand", :pid => member_of_brand_pid)
        end
      else
        xml.member_of_brand
      end

      xml.version_of do
        xml.link(:rel => "pips-meta:#{version_of_type || 'episode'}", :pid => version_of_pid)
      end

      xml.master_brand

      xml.version_types do
        xml.version_reason(version_reason)
        xml.version_type(:version_type_id => version_type_id)
      end

      unless language.nil?
        xml.languages do
          xml.language(language.to_s.upcase)
        end
      end

      if duration.is_a?(Numeric)
        hours = duration.to_i / 3600
        secs = duration % 3600
        xml.duration(sprintf("%2.2d:%2.2d:%2.2d", hours, secs / 60, secs % 60))
      else
        xml.duration(duration)
      end

      xml.subtitles
      xml.genres
      xml.formats
      xml.classifications
      xml.warnings
      xml.competition_warning(:value => competition_warning || 'false')
      xml.credits
      xml.audio_visual_attributes do
        xml.aspect_ratio(aspect_ratio) unless aspect_ratio.nil?
        xml.sound_format(sound_format) unless sound_format.nil?
      end
      xml.source_asset
      xml.links
    end
  end
end
