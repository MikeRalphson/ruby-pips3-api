module Pips3Api
  class MediaAsset < Base
    attr_accessor :pid, :version_pid, :media_asset_profile_pid
    attr_accessor :filename, :media_file_size, :actual_total_bitrate
    attr_accessor :actual_video_bitrate, :actual_audio_bitrate
    attr_accessor :media_duration, :start_offset, :end_offset
    attr_accessor :is_hidden, :is_deleted
    set_collection_name "media_asset"
    set_default_identifier_type "pid"

    def self.find_all_by_version(version)
      find_all_by_version_pid(version.pid)
    end

    def self.find_all_by_version_pid(version_pid)
      self.find(:all, :from => "version/pid.#{version_pid}/media_assets", :query => { "rows" => 50 })
    end

    def parse_xml(data)
      self.version_pid = data.at('media_asset_of/link')['pid']
      self.media_asset_profile_pid = data.at('media_asset_profile/link')['pid']

      self.filename = data.at('filename').inner_text
      self.media_file_size = inner_int_or_nil(data, 'media_file_size')
      self.actual_total_bitrate = inner_int_or_nil(data, 'actual_total_bitrate_kbps')
      self.actual_video_bitrate = inner_int_or_nil(data, 'actual_video_bitrate_kbps')
      self.actual_audio_bitrate = inner_int_or_nil(data, 'actual_audio_bitrate_kbps')
      self.media_duration = inner_int_or_nil(data, 'media_duration_seconds')
      self.start_offset = inner_int_or_nil(data, 'start_offset_milliseconds')
      self.end_offset = inner_int_or_nil(data, 'end_offset_milliseconds')
      self.is_hidden = data.at('is_hidden')['value'] == 'true'
      self.is_deleted = data.at('is_deleted')['value'] == 'true'
    end

    def version
      @version ||= Version.find( version_pid )
    end

    private
    def inner_int_or_nil(data, path)
      node = data.at(path)
      # TODO this was breaking some tests, why?
      # node.inner_text if node and node.children
      node.inner_text.to_i unless node.nil? or node.inner_text.nil? or node.inner_text.empty?
    end

  end
end
