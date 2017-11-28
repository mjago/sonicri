require "xml"
require "colorize"
require "file_utils"

module PodPicr
  class List
    TEMP_LIST   = "tmp.opml"
    DEBUG_LIST  = false
    FileAddress = "http://www.bbc.co.uk/podcasts.opml"
    OPML_File   = "podcasts.xml"

    # FileAddress = "http://feeds.twit.tv/twitshows.opml"

    def initialize
      @data = [] of ListStruct
      @selected_idx = 0
      @results = {} of String => Array(String)
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
          temp << d.xmlUrl
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
      true
    end

    def update
      Downloader.new.fetch(FileAddress, TEMP_LIST)
      @document = XML.parse(TEMP_LIST)
      # check_for_errors
      FileUtils.cp(TEMP_LIST, OPML_File) # "program.rss")
    end

    # parse OPML file
    # Extract each outline and store in @data array
    # Sort @data array by station alphabetically
    def parse
      parse_OPML_local(OPML_File)
      document = @document.not_nil!
      parse_title(document)
      parse_date_modified(document)
      body = parse_body(document)
      outlines = parse_outlines(body)
      outlines.each do |outline|
        outline_set = parse_program(outline)
        outline_set.each do |st|
          clear_station_results
          extract_program_attrs(st)
          store_station_data(st)
          puts if DEBUG_LIST
        end
      end
      sort_stations
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

    private def parse_OPML_local(file)
      list = File.open(file, "r")
      @document = XML.parse(list)
      check_for_errors
    end

    private def xpath_parse_first(doc, str)
      doc.xpath_nodes(str).first
    end

    private def parse_title(doc)
      t = xpath_parse_first(doc, "opml/head/title")
      t = t.children.first.text if t
      puts "title: #{t}" if DEBUG_LIST
      t
    end

    private def parse_date_modified(doc)
      dm = xpath_parse_first(doc, "opml/head/dateModified")
      dm.children.first.text if dm
      puts "date_modified: #{dm}" if DEBUG_LIST
      dm
    end

    private def parse_body(doc)
      xpath_parse_first(doc, "opml/body")
    end

    private def parse_outlines(doc)
      doc.xpath_nodes("outline")
    end

    private def parse_station(doc)
      st = doc.xpath_nodes("./@text")[0].text
      puts "station: #{st}".colorize(:cyan) if DEBUG_LIST
      st
    end

    private def parse_program(doc)
      doc.xpath_nodes("./outline")
    end

    private def parse_prog_attribute(doc, attr)
      doc.xpath_nodes("outline/#{attr}")
    end

    private def clear_station_results
      ListStruct.names.each do |attr|
        @results[attr] = [] of String
      end
      puts ("#   " * 16).colorize(:cyan) if DEBUG_LIST
    end

    private def extract_program_attrs(prog)
      ListStruct.names.each do |attr|
        prog_attr = parse_prog_attribute(prog, attr)
        if prog_attr
          prog_attr.each do |at|
            @results[attr] << at.text.to_s
          end
        else
          @results[attr] << ""
        end
      end
    end

    private def store_station_data(st)
      station = parse_station(st)
      @results["@description"].size.times do |count|
        puts "#{(count + 1).colorize(:cyan)}:" if DEBUG_LIST
        hash = {} of String => String
        hash["station"] = station
        ListStruct.names.each do |attr|
          unless @results[attr].empty?
            res = @results[attr].shift
            puts "#{attr[1..-1].capitalize.colorize(:green)}: #{(res).colorize(:yellow)}" if DEBUG_LIST
            hash[attr[1..-1]] = res
          end
        end
        assign_data(hash)
      end
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
