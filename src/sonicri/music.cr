# coding: utf-8

module Sonicri
  MUSIC_ROOT = File.expand_path(File.read("./music_root.rc").strip)

  class Music
    property channels

    def initialize
      @albums = Albums.new
      @albums.parse_music_files(".")
      @channels = @albums
    end

    def file_with_path(file)
      File.join(@albums.build_dir, file)
    end
  end

  class Albums
    @content = [] of String
    property path = [] of String

    def root?
      @path.empty?
    end

    def push(dir)
      @path << "#{dir}"
    end

    def pop
      @path.pop
    end

    def reset
      #     @path = [] of String
    end

    def content
      p = ""
      @path.each do |dir|
        p = File.join(p, dir)
      end
      parse_music_files p
    end

    def parse_music_files(file)
      temp = [] of String
      Dir.children(File.join(MUSIC_ROOT, file)).each do |b|
        temp << b if directory?(b) || mp3_file?(b)
      end
      @content = temp.sort { |x, y| x <=> y }
    end

    def directory?(file)
      File.directory?(File.join(build_dir, file))
    end

    def mp3_file?(file)
      File.extname(File.join(file)) == ".mp3"
    end

    def build_dir
      File.join(MUSIC_ROOT, @path.each.join('/'))
    end
  end
end
