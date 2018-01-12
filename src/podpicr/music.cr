# coding: utf-8

module PodPicr
  MUSIC_ROOT = "/Users/martyn/Music/new/"

  class Music
    getter :albums
    setter :path

    def initialize
      @albums = [] of String
      @path = [] of String
      parse_music_files(".")
    end

    def top_level?
      @path.empty?
    end

    def push_level(dir)
      @path << "#{dir}"
    end

    def pop_level
      @path.pop
    end

    def file_with_path(file)
      File.join(build_dir, file)
    end

    def parse_music_files(file)
      @albums = [] of String
      Dir.children(File.join(MUSIC_ROOT, file)).each do |b|
        @albums << b if directory?(b) || mp3_file?(b)
      end
      @albums
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

    def contents
      p = ""
      @path.each do |dir|
        p = File.join(p, dir)
      end
      parse_music_files p
    end
  end
end
