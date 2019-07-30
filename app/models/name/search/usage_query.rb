# frozen_string_literal: true

# For a given name ID, retrieve a set of grouped and ordered
# instance results suitable for displaying the name usages.
class Name::Search::UsageQuery
  attr_reader :results, :id
  def initialize(name_id)
    debug('start')
    @id = name_id
    build_query
  end

  def build_query
    debug('build_query: join the name to instance, then to instance type, reference, then to author, left outer join to tree')
    @results = Name.where(id: @id)
                   .joins(instances: [:instance_type, reference: :author])
                   .select(columns)
                   .group(grouping)
                   .order(ordering)
  end
  #                .left_outer_joins(tree_elements: [{tree_version_elements: {tree_version: :tree}}])
  #                .where("#{not_on_any_tree} or #{on_the_current_accepted_tree}")
  #                .where(' tree_element.id is null or ( tree.accepted_tree = true and tree_version.id = tree.current_tree_version_id)')

  def not_on_any_tree
    ' tree_element.id is null '
  end

  def on_the_current_accepted_tree
    ' ( tree.accepted_tree = true and tree_version.id = tree.current_tree_version_id)'
  end

  def columns
    "name.id name_id,name.full_name, name.full_name_html, \
    reference.id reference_id, reference.year reference_year, instance_type.id,\
    instance_type.name instance_type_name, instance_type.misapplied, author.id,\
    reference.citation_html,coalesce(reference.year,9999), author.name,  \
    primary_instance, instance.id instance_id, instance.page instance_page, \
    instance.cited_by_id, instance.bhl_url, \
    instance.page_qualifier instance_page_qualifier, \
    instance_type.has_label, instance_type.of_label, \
    reference.citation reference_citation, \
    reference.citation_html reference_citation_html"
  end

  def grouping
    "name.id, name.full_name, reference.id, reference.year, instance_type.id, \
    instance_type.name, instance_type.misapplied,
    author.id,reference.citation_html,coalesce(reference.year,9999),  \
    author.name, primary_instance, instance.id, instance.page, \
    instance.cited_by_id, \
    instance_type.has_label, instance_type.of_label, \
    instance.page_qualifier, reference.citation "
    # , tree_element.id, \
    # tree_element.profile, \
    # tree.config, \
    # tree_element.excluded "
  end

  # if published in the same year, put primary instances first,
  # so sort by year, primary instance, date, author name 
  def ordering
    "coalesce(substr(reference.iso_publication_date,1,4),'9999'), \
    primary_instance desc, \
    coalesce(reference.iso_publication_date,'9999'), \
    author.name, instance.id"
  end

  def debug(s)
    Rails.logger.debug("==============================================")
    Rails.logger.debug("Name::Search::UsageQuery: #{s}")
    Rails.logger.debug("==============================================")
  end
end
