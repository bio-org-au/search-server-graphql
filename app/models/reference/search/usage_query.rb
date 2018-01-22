# frozen_string_literal: true

# For a given name ID, retrieve a set of grouped and ordered
# instance results suitable for displaying the name usages.
class Reference::Search::UsageQuery
  attr_reader :results, :id
  def initialize(name_id)
    @id = name_id
    build_query
  end

  def build_query
    Rails.logger.debug('Reference::Search::UsageQuery start ====================')
    @results = Name.where(id: @id)
                   .joins(instances: [:instance_type, reference: :author])
                   .select(columns)
                   .group(grouping)
                   .order(ordering)
    Rails.logger.debug('Reference::Search::UsageQuery end   ====================')
  end

  def columns
    "name.id name_id,name.full_name, name.full_name_html, \
    reference.id reference_id, reference.year reference_year, instance_type.id,\
    instance_type.name instance_type_name, instance_type.misapplied, author.id,\
    reference.citation_html,coalesce(reference.year,9999), author.name,  \
    primary_instance, instance.id instance_id, instance.page instance_page, \
    instance.page_qualifier instance_page_qualifier, \
    reference.citation reference_citation"
  end

  def grouping
    "name.id, name.full_name, reference.id, reference.year, instance_type.id, \
    instance_type.name, instance_type.misapplied,
    author.id,reference.citation_html,coalesce(reference.year,9999),  \
    author.name, primary_instance, instance.id, instance.page, \
    instance.page_qualifier, reference.citation"
  end

  def ordering
    'coalesce(reference.year,9999), primary_instance desc, author.name'
  end
end
