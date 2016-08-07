module Pips3Api
  class MasterBrand < Base
    attr_accessor :mid, :name
    set_collection_name "master_brand"
    set_default_identifier_type "mid"

    def parse_xml(data)
      self.mid = data["mid"]
      self.name = data.at("name").inner_text
    end
  end
end
