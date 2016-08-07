require "digest/md5"
require "fileutils"

module Pips3Api
  class Cache
    attr_reader :cache_dir

    EXCLUDED_DIRS = ['.', '..', '.svn'].freeze

    def initialize(cache_dir)
      raise "cache_dir does not exist: #{cache_dir}" unless File.exist? cache_dir
      @cache_dir = cache_dir
    end

    def exist?(name)
      file_name = get_path(name)
      File.exist?(file_name)
    end

    def fetch(key)
      if exist?(key)
        result = read(key)
      else
        result = yield
        write(key, result)
      end
      result
    end

    def read(name)
      file_name = get_path(name)
      if File.exist?(file_name)
        File.open(file_name) { |f| YAML.load(f) }
      end
    rescue
      nil
    end

    def write(name, value, options = nil)
      unless value.nil?
        file_name = get_path(name)
        check_path(File.dirname(file_name))
        File.open(file_name, "w") { |f| YAML.dump(value, f) }
        true
      end
    end

    def clear
      root_dirs = Dir.entries(cache_dir).reject { |f| EXCLUDED_DIRS.include? f }
      FileUtils.rm_r(root_dirs.collect{ |f| File.join(cache_dir, f) })
    end

    def clear_old_entries(age=86400)
      fresh_time = Time.now - age
      entries_to_delete = Dir.glob("#{cache_dir}/**/*").
        reject { |fn| File.directory? fn }.
        reject { |fn| EXCLUDED_DIRS.include? fn }.
        reject { |fn| File.mtime(fn) > fresh_time }

      entries_to_delete.each { |fn| FileUtils.rm fn }
      true
    end

    private

    def get_path(key)
      md5 = Digest::MD5.hexdigest(key.to_s).to_s
      dir = File.join(cache_dir, md5.split(//)[0..2])
      File.join(dir, md5)
    end

    # Make sure a file path's directories exist.
    def check_path(path)
      FileUtils.makedirs(path) unless File.exist?(path)
    end
  end
end
