# frozen_string_literal: true

# For a given instance ID, retrieve a set of ordered synonyms
class Taxonomy::Search::Synonyms < Array
  def initialize(instance_id)
    @instance = Instance.find(instance_id)
    build
  end

  def build
    @instance.synonyms.sort do |x, y|
      [x.instance_type.misapplied.to_s, x.name.full_name, x.try("this_cites").try("reference").try("year") || 9999] <=> [y.instance_type.misapplied.to_s, y.name.full_name, y.try("this_cites").try("reference").try("year") || 9999]
    end.collect do |synonym|
      record = OpenStruct.new
      record.id = synonym.id
      record.name_id = synonym.name_id
      record.page = synonym.page
      record.page_qualifier = synonym.this_cites.try('page_qualifier')
      record.simple_name = synonym.name.simple_name
      record.full_name = synonym.name.full_name
      record.full_name_html = synonym.name.full_name_html
      record.is_doubtful = synonym.instance_type.doubtful?
      record.is_misapplied = synonym.instance_type.misapplied?
      record.name_status = synonym.name.name_status.name
      if record.is_misapplied
        record.misapplication_details = OpenStruct.new
        record.misapplication_details.name_author_string = synonym.this_cites.name.author_component_of_full_name.strip
        record.misapplication_details.cites_simple_name = synonym.this_is_cited_by.name.simple_name
        record.misapplication_details.page = synonym.this_cites.page
        record.misapplication_details.cites_reference_citation = synonym.this_cites.reference.citation 
        record.misapplication_details.cites_reference_citation_html = synonym.this_cites.reference.citation_html 
      end
      self.push(record)
    end
  end
end
