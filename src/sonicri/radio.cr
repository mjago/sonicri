# coding: utf-8

module Sonicri
  class Radio
    struct RStation
      property :name
      property :url

      def initialize(@name : String = name, @url : String = url)
      end
    end

    def data
      [
        "BBC Radio 1",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_radio1_mf_p",
        "BBC Radio 1xtra",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_radio1xtra_mf_p",
        "BBC Radio 2",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_radio2_mf_p",
        "BBC Radio 3",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_radio3_mf_p",
        "BBC Radio 4FM",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_radio4fm_mf_p",
        "BBC Radio 4LW",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_radio4lw_mf_p",
        "BBC Radio 4 Extra",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_radio4extra_mf_p",
        "BBC Radio 5 Live",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_radio5live_mf_p",
        "BBC Radio 6 Music",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_6music_mf_p",
        "BBC Asian Network",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_asianet_mf_p",
        "BBC World Service UK stream",
        "http://bbcwssc.ic.llnwd.net/stream/bbcwssc_mp1_ws-eieuk",
        "BBC World Service News stream",
        "http://bbcwssc.ic.llnwd.net/stream/bbcwssc_mp1_ws-einws",
        "Radio Cymru",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_cymru_mf_p",
        "BBC Radio Foyle",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_foyle_mf_p",
        "BBC Radio nan Gàidheal",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_nangaidheal_mf_p",
        "BBC Radio Scotland",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_scotlandfm_mf_p",
        "BBC Radio Ulster",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_ulster_mf_p",
        "BBC Radio Wales",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_walesmw_mf_p",
        "BBC Radio Berkshire",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrberk_mf_p",
        "BBC Radio Bristol",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrbris_mf_p",
        "BBC Radio Cambridgeshire",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrcambs_mf_p",
        "BBC Radio Cornwall",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrcorn_mf_p",
        "BBC Coventry &#038; Warwickshire",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrwmcandw_mf_p",
        "BBC Radio Cumbria",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrcumbria_mf_p",
        "BBC Radio Derby",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrderby_mf_p",
        "BBC Radio Devon",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrdevon_mf_p",
        "BBC Essex",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lressex_mf_p",
        "BBC Radio Gloucestershire",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrgloucs_mf_p",
        "BBC Radio Guernsey",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrguern_mf_p",
        "BBC Hereford &#038; Worcester",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrhandw_mf_p",
        "BBC Radio Humberside",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrhumber_mf_p",
        "BBC Radio Jersey",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrjersey_mf_p",
        "BBC Radio Kent",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrkent_mf_p",
        "BBC Radio Lancashire",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrlancs_mf_p",
        "BBC Radio Leeds",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrleeds_mf_p",
        "BBC Radio Leicester",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrleics_mf_p",
        "BBC Radio Lincolnshire",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrlincs_mf_p",
        "BBC Radio London",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrldn_mf_p",
        "BBC Radio Manchester",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrmanc_mf_p",
        "BBC Radio Merseyside",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrmersey_mf_p",
        "BBC Newcastle",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrnewc_mf_p",
        "BBC Radio Norfolk",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrnorfolk_mf_p",
        "BBC Radio Northampton",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrnthhnts_mf_p",
        "BBC Radio Nottingham",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrnotts_mf_p",
        "BBC Radio Oxford",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lroxford_mf_p",
        "BBC Radio Sheffield",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrsheff_mf_p",
        "BBC Radio Shropshire",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrshrops_mf_p",
        "BBC Radio Solent",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrsolent_mf_p",
        "BBC Somerset",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrsomer_mf_p",
        "BBC Radio Stoke",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrsomer_mf_p",
        "BBC Radio Suffolk",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrsuffolk_mf_p",
        "BBC Surrey",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrsurrey_mf_p",
        "BBC Sussex",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrsussex_mf_p",
        "BBC Tees",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrtees_mf_p",
        "BBC Three Counties Radio",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lr3cr_mf_p",
        "BBC Wiltshire",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrwilts_mf_p",
        "BBC WM 95.6",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lrwm_mf_p",
        "BBC Radio York",
        "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_lryork_mf_p",
      ]
    end

    def initialize
      @stations = [] of RStation
      name = ""
      url = ""
      data.each_with_index do |x, idx|
        if idx.even?
          name = x
        else
          url = x
          @stations << RStation.new(name, url)
        end
      end
    end

    def station_list
      temp = [] of String
      @stations.each { |s| temp << s.name }
      temp
    end

    def url_of(name)
      @stations.each do |s|
        return s.url if s.name == name
      end
    end
  end
end

# rs = Sonicri::Radio.new
# puts rs.stations.inspect
