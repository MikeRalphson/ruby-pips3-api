module Pips3Api
  class Contribution < Base
    attr_accessor :pid, :contribution_by_pid, :contribution_to_pid, :contribution_to_type
    attr_accessor :character, :role_description, :role_id, :character_name, :position
    set_collection_name "contribution"
    set_default_identifier_type "pid"

    def self.find_all_by_segment(segment)
      self.find(:all, :from => "segment/pid.#{segment.pid}/contributions", :query => { :expand => "contribution_by" })
    end

    def parse_xml(data)
      contribution_to = data.at('contribution_to/link')
      unless contribution_to.nil?
        self.contribution_to_pid = contribution_to['pid']
        self.contribution_to_type = contribution_to['rel'].sub(/pips-meta:/,'')
      end

      # Has :expand => 'contribution_by' been set?
      contributor = data.at('contribution_by/contributor')
      unless contributor.nil?
        self.contribution_by_pid = contributor['pid']
        @contributor = Contributor.new(contributor)
      else
        link = data.at('contribution_by/link')
        unless link.nil?
          self.contribution_by_pid = link['pid']
        end
      end

      self.character = data.at('character').inner_text
      self.role_description = data.at('role/description').inner_text
      self.role_id = data.at('role/link')['credit_role_id'] unless data.at('role/link').nil?
      self.character_name = data.at('character_name').inner_text
      self.position = data.at('position').inner_text.to_i
    end

    def build_xml(xml)
      xml.contribution_to do
        xml.link(:rel => "pips-meta:#{contribution_to_type}", :pid => contribution_to_pid)
      end
      xml.contribution_by do
        xml.link(:rel => "pips-meta:contributor", :pid => contribution_by_pid)
      end

      xml.character(character)
      xml.role do
        xml.description(role_description)
        xml.link(:rel => "pips-meta:credit_role", :credit_role_id => role_id)
      end
      xml.character_name(character_name)
      xml.position(position)
      xml.links
    end

    def contributor
      @contributor ||= Contributor.find(contribution_by_pid)
    end

    def contributor=(contributor)
      @contributor = contributor
      self.contribution_by_pid = contributor ? contributor.pid : nil
    end

    def contribution_to
      @contribution_to ||= load_contribution_to
    end

    def contribution_to=(contributable)
      @contribution_to = contributable
      if contributable.nil?
        self.contribution_to_pid = nil
        self.contribution_to_type = nil
      else
        self.contribution_to_pid = contributable.pid
        self.contribution_to_type = contributable.class.to_s.split("::").last.downcase
      end
    end
    
    def role
      @role ||= CreditRole.find(role_id)
    end

    private

    def load_contribution_to
      if contribution_to_type and contribution_to_pid
        class_name = contribution_to_type.split('_').collect!{ |w| w.capitalize }.join
        klass = Pips3Api.const_get(class_name)
        klass.find contribution_to_pid
      end
    end
  end
end
