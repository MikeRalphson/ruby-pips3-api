module Pips3Api
  class Service < Base
    attr_accessor :sid, :name, :region, :type, :url_key
    set_collection_name 'service'
    set_default_identifier_type 'sid'

    # One day this will be in PIPs
    URL_KEYS = {
      'cbeebies' => 'cbeebies',
      'cbbc' => 'cbbc',
      'bbc_world_service' => 'worldserviceradio',
      'bbc_world_news' => 'worldnews',
      'bbc_wm' => 'wm',
      'bbc_two' => 'bbctwo',
      'bbc_three' => 'bbcthree',
      'bbc_three_counties_radio' => 'threecountiesradio',
      'bbc_tees' => 'bbctees',
      'bbc_switch' => 'switch',
      'bbc_sport' => 'sport',
      'bbc_southern_counties_radio' => 'southerncounties',
      'bbc_school_radio' => 'schoolradio',
      'bbc_radio_york' => 'radioyork',
      'bbc_radio_wiltshire' => 'bbcwiltshire',
      'bbc_radio_wales' => 'radiowales',
      'bbc_radio_ulster' => 'radioulster',
      'bbc_radio_two' => 'radio2',
      'bbc_radio_three' => 'radio3',
      'bbc_radio_swindon' => 'swindon',
      'bbc_radio_sussex' => 'bbcsussex',
      'bbc_radio_surrey' => 'bbcsurrey',
      'bbc_radio_suffolk' => 'radiosuffolk',
      'bbc_radio_stoke' => 'radiostoke',
      'bbc_radio_somerset_sound' => 'bbcsomerset',
      'bbc_radio_solent' => 'radiosolent',
      'bbc_radio_shropshire' => 'radioshropshire',
      'bbc_radio_sheffield' => 'radiosheffield',
      'bbc_radio_scotland' => 'radioscotland',
      'bbc_radio_oxford' => 'bbcoxford',
      'bbc_radio_one' => 'radio1',
      'bbc_radio_nottingham' => 'radionottingham',
      'bbc_radio_northampton' => 'radionorthampton',
      'bbc_radio_norfolk' => 'radionorfolk',
      'bbc_radio_newcastle' => 'bbcnewcastle',
      'bbc_radio_nan_gaidheal' => 'radionangaidheal',
      'bbc_radio_merseyside' => 'radiomerseyside',
      'bbc_radio_manchester' => 'radiomanchester',
      'bbc_radio_lincolnshire' => 'bbclincolnshire',
      'bbc_radio_leicester' => 'radioleicester',
      'bbc_radio_leeds' => 'radioleeds',
      'bbc_radio_lancashire' => 'radiolancashire',
      'bbc_radio_kent' => 'radiokent',
      'bbc_radio_jersey' => 'radiojersey',
      'bbc_radio_humberside' => 'radiohumberside',
      'bbc_radio_hereford_worcester' => 'bbcherefordandworcester',
      'bbc_radio_guernsey' => 'bbcguernsey',
      'bbc_radio_gloucestershire' => 'radiogloucestershire',
      'bbc_radio_foyle' => 'radiofoyle',
      'bbc_radio_four' => 'radio4',
      'bbc_radio_four_extra' => 'radio4extra',
      'bbc_radio_five_live' => '5live',
      'bbc_radio_five_live_sports_extra' => '5livesportsextra',
      'bbc_radio_five_live_olympics_extra' => '5liveolympicsextra',
      'bbc_radio_essex' => 'bbcessex',
      'bbc_radio_devon' => 'radiodevon',
      'bbc_radio_derby' => 'radioderby',
      'bbc_radio_cymru' => 'radiocymru',
      'bbc_radio_cumbria' => 'radiocumbria',
      'bbc_radio_coventry_warwickshire' => 'bbccoventryandwarwickshire',
      'bbc_radio_cornwall' => 'radiocornwall',
      'bbc_radio_cambridge' => 'radiocambridgeshire',
      'bbc_radio_bristol' => 'radiobristol',
      'bbc_radio_berkshire' => 'radioberkshire',
      'bbc_parliament' => 'parliament',
      'bbc_one' => 'bbcone',
      'bbc_news24' => 'bbcnews',
      'bbc_news' => 'news',
      'bbc_london' => 'bbclondon',
      'bbc_hd' => 'bbchd',
      'bbc_four' => 'bbcfour',
      'bbc_asian_network' => 'asiannetwork',
      'bbc_alba' => 'bbcalba',
      'bbc_7' => 'radio7',
      'bbc_6music' => '6music',
      'bbc_1xtra' => '1xtra',
    }

    def parse_xml(data)
      self.name = data.at("name").inner_text
      self.region = data.at("region").inner_text
      self.type = data.at("type").inner_text
      self.url_key = URL_KEYS[self.sid]
    end
  end
end
