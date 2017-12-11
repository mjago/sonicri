require "xml"
require "colorize"
require "file_utils"

module PodPicr
  class List
    TEMP_LIST    = "temp.opml"
    DEBUG_LIST   = false
    BbcOpmlAddr  = "http://www.bbc.co.uk/podcasts.opml"
    TwitOpmlAddr = "http://feeds.twit.tv/twitshows.opml"
    OPML_File    = "temp.xml"

    getter parsed

    def initialize
      @data = [] of ListStruct
      @selected_idx = 0
      @results = {} of String => Array(String)
      @station = ""
      @twit = false
      @parsed = false
    end

    def parse
      prepare_station_struct
      update BbcOpmlAddr
      parse_OPML_local(OPML_File)
      do_parse
      update TwitOpmlAddr
      parse_OPML_local(OPML_File)
      do_parse
      update "http://www.cbc.ca/podcasting/podcasts.opml"
      parse_OPML_local(OPML_File)
      do_parse
      parse_OPML_local("opml/miscellaneous.opml")
      do_parse
      parse_OPML_local("opml/other.opml")
      do_parse
      sort_stations
      @parsed = true
    end

    def stations
      temp = [] of String
      @data.each do |d|
        temp << d.station
      end
      temp.uniq
    end

    def shows(station)
      temp = [] of String
      @data.each do |d|
        if d.station == station
          temp << d.text
        end
      end
      temp.sort { |x, y| x <=> y }
    end

    def xmlUrl(title)
      temp = [] of String
      @data.each do |d|
        if d.text == title
          temp << d.url
        end
      end
      temp
    end

    def channel_url(station)
      @data.each do |d|
        temp << text if (d.station == station)
      end
      temp.uniq
    end

    def outdated? # todo
      time = PodPicr::Time.new
      false
      #true
    end

    def update
      # todo
    end

    def update(addr)
      Downloader.fetch(addr, TEMP_LIST)
      @document = XML.parse(TEMP_LIST)
      # check_for_errors
      FileUtils.cp(TEMP_LIST, OPML_File) # "program.rss")
    end

    def selected
      @data[@selected_idx]
    end

    private def check_for_errors
      if @document.nil?
        return
      else
        errors = @document.not_nil!.errors
        if errors
          raise("Error: invalid OPMl format \n#{errors}")
        end
      end
    end

    private def find_head(root)
      root.children.each do |child|
        if child.name == "head"
          return child
        end
      end
      raise "Couldn't find head!"
    end

    private def find_body(root)
      root.children.each do |child|
        if child.name == "body"
          return child
        end
      end
      raise "Couldn't find body!"
    end

    private def get_title(head)
      head.children.select(&.element?).each do |child|
        return child.content
      end
      raise "Couldn't find title"
    end

    private def find_outline_depth(node, depth = 0)
      if node.children.each do |x|
           if x.name == "outline"
             return find_outline_depth(x, depth + 1)
           end
         end
      end
      depth
    end

    private def parse_programs(node, station)
      programs = [] of Hash(String, String)
      node.children.each do |x|
        if x.name == "outline"
          program = {"station" => station}
          count = 0
          x.attributes.each do |attr|
            case attr.name
            when "text", "description"
              count += 1
              program[attr.name] = attr.content
            when "url", "xmlUrl"
              count += 1
              program["url"] = attr.content
            end
          end
          if count == 3
            programs << program
          end
        end
      end
      programs
    end

    private def do_parse
      stations = [] of Hash(String, String)
      doc = @document.not_nil!
      opml = doc.root.not_nil!
      head = find_head opml
      title = get_title head
      body = find_body opml
      depth = find_outline_depth body
      case depth
      when 1
        programs = parse_programs(body, title)
        programs.each do |prog|
          stations << prog
        end
      when 3
        station = ""
        title_outline = nil
        body.children.each do |x|
          if x.name == "outline"
            x.children.each do |y|
              if y.name == "outline"
                y.attributes.each do |attr|
                  if attr.name == "text"
                    unless attr.content.strip == ""
                      station = attr.content
                      programs = parse_programs(y, station)
                      programs.each do |prog|
                        stations << prog
                      end
                    end
                  end
                end
              end
            end
          end
        end
        station = ""
      when 4
        title_outline = nil
        body.children.each do |x|
          if x.name == "outline"
            x.children.each do |y|
              if y.name == "outline"
                y.attributes.each do |attr|
                  if attr.name == "text"
                    unless attr.content.strip == ""
                      station = attr.content
                      y.children.each do |z|
                        if z.name == "outline"
                          programs = parse_programs(z, station)
                          programs.each do |prog|
                            stations << prog
                          end
                        end
                      end
                      programs = parse_programs(y, station)
                      programs.each do |prog|
                        stations << prog
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
      stations.each { |station| assign_data(station) }
    end

    private def parse_OPML_local(file)
      list = File.open(file, "r")
      @document = XML.parse(list)
      check_for_errors
    end

    private def prepare_station_struct
      ListStruct.names.each do |attr|
        @results[attr] = [] of String
      end
      puts ("#   " * 16).colorize(:cyan) if DEBUG_LIST
    end

    # Sort @data array by station alphabetically
    private def sort_stations
      @data = @data.sort { |x, y| x.station <=> y.station }
    end

    private def assign_data(hash)
      list = ListStruct.new
      list.assign(hash)
      @data << list
    end
  end
end
