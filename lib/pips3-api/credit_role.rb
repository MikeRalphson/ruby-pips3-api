module Pips3Api
  class CreditRole < Base
    attr_accessor :credit_role_id, :name, :description
    set_collection_name 'credit_role'
    set_default_identifier_type 'credit_role_id'

    def parse_xml(data)
      self.name = data.at("name").inner_text
      self.description = data.at("description").inner_text
    end

    def to_s
      name
    end
  end
end
