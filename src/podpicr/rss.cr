require "xml"

module PodPicr
  class RSS
    TEMP_RSS = "/tmp/tmp.rss"
    RSS_FILE = "program.rss"

    getter results

    def initialize
      @results = [] of Hash(String, String)
    end

    def results(param)
      temp = [] of String
      @results.each do |res|
        res.try { |r| temp << r[param].not_nil! }
      end
      temp
    end

    private def select(val : String)
      puts "rss selected #{val}"
      exit
    end

    private def fetch(url)
      Downloader.new.fetch(url, TEMP_RSS)
      FileUtils.cp(TEMP_RSS, RSS_FILE)
      true
    end

    def parse(url)
      @results = [] of Hash(String, String)
      fetch(url)
      f = File.open(RSS_FILE)
      document = XML.parse(f)
      check_for_errors(document)
      title = parse_title(document)
      items = parse_items(document)
      results = [] of Hash(String, String)
      items.each do |item|
        result = {} of String => String
        result["title"] = parse_item_title(item)
        result["description"] = parse_item_description(item)
        result["pubdate"] = parse_item_pubdate(item)
        result["url"] = parse_item_url(item)
        result["length"] = parse_item_length(item)
        result["type"] = parse_item_type(item)
        @results << result
        #  puts
        #  puts "item_title       : #{result["title"]} "
        #  puts "item_link        : #{result["link"]} "
        #  puts "item_description : #{result["description"]} "
        #  puts "item_summary     : #{result["summary"]} "
        #  puts "item_pubdate     : #{result["pubdate"]} "
        #  puts "item_url         : #{result["url"]} "
        #  puts "item_length      : #{result["length"]} "
        #  puts "item_type        : #{result["type"]} "
      end
      @results = @results.sort { |x, y| x["title"] <=> y["title"] }
      true
    end

    private def check_for_errors(doc)
      if doc.nil?
        return
      else
        errors = doc.not_nil!.errors
        if errors
          raise("Error: invalid rss format \n#{errors}")
        end
      end
    end

    private def parse_title(doc)
      doc.xpath_nodes("//channel/title").first.text
    end

    private def parse_items(doc)
      doc.xpath_nodes("//item")
    end

    private def parse_item_title(item)
      item.xpath_nodes("title").first.text
    end

    private def parse_item_link(item)
      item.xpath_nodes("link").first.text
    end

    private def parse_item_description(item)
      item.xpath_nodes("description").first.text
    end

    private def parse_item_i_summary(item)
      x = item.xpath_nodes("t:subtitle",
        namespaces =
          {'t' => "http://www.itunes.com/dtds/podcast-1.0.dtd"})
      x.first.text if x
    end

    private def parse_item_i_subtitle(item)
      x = item.xpath_nodes("t:subtitle",
        namespaces =
          {'t' => "http://www.itunes.com/dtds/podcast-1.0.dtd"})
      x.first.text if x
    end

    private def parse_item_i_keywords(item)
      x = item.xpath_nodes("t:keywords",
        namespaces =
          {'t' => "http://www.itunes.com/dtds/podcast-1.0.dtd"})
      x.first.text if x
    end

    private def parse_item_i_category(item)
      x = item.xpath_nodes("t:category/@text",
        namespaces =
          {'t' => "http://www.itunes.com/dtds/podcast-1.0.dtd"})
      x.first.text if x
    end

    private def parse_item_pubdate(item)
      item.xpath_nodes("pubDate").first.text
    end

    private def parse_item_url(item)
      item.xpath_nodes("enclosure/@url").first.text
    end

    private def parse_item_length(item)
      item.xpath_nodes("enclosure/@length").first.text
    end

    private def parse_item_type(item)
      item.xpath_nodes("enclosure/@type").first.text
    end
  end
end
