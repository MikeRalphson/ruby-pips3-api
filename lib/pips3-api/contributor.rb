module Pips3Api
  class Contributor < Base
    attr_accessor :pid, :contributor_type, :disambiguation
    attr_accessor :lang, :presentation_name, :title, :given_name, :family_name, :sort_name
    set_collection_name "contributor"
    set_default_identifier_type "pid"

    def parse_xml(data)
      self.contributor_type = data.at("type").inner_text
      self.lang = data.at("name")['lang']
      self.presentation_name = data.at("name/presentation").inner_text if data.at('name/presentation')
      self.title = data.at("name/title").inner_text if data.at('name/title')
      self.given_name = data.at("name/given").inner_text if data.at('name/given')
      self.family_name = data.at("name/family").inner_text if data.at('name/family')
      self.sort_name = data.at("name/sort").inner_text if data.at('name/sort')
      self.disambiguation = data.at("disambiguation").inner_text if data.at('disambiguation')
    end

    def build_xml(xml)
      xml.canonical_contributor
      xml.type(contributor_type)
      xml.name(:lang => lang || '') do
        xml.presentation(presentation_name)
        xml.title(title)
        xml.given(given_name)
        xml.family(family_name)
        xml.sort(sort_name)
      end
      xml.disambiguation(disambiguation)
      xml.links
    end

    def musicbrainz_id=(id)
      ids["musicbrainz-artist_id"] = id
    end

    def musicbrainz_id
      ids["musicbrainz-artist_id"]
    end

    def name
      unless presentation_name.nil? or presentation_name.empty?
        presentation_name
      else
        [title, given_name, family_name].compact.join(' ')
      end
    end
  end
end
