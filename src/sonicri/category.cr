# coding: utf-8

module Sonicri
  class Categories
    def content
      %w[Podcasts Music Radio\ Stations]
    end

    def reset
    end

    def root?
    end
  end

  class Category
    property channels

    def initialize
      @channels = Categories.new
    end

    def file_with_path(file)
      File.join(@albums.build_dir, file)
    end
  end
end
