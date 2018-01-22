# frozen_string_literal: true

# For a given name ID, retrieve a set of grouped and ordered
# instance results suitable for displaying the name usages.
class Name::Search::UsageQuery
  attr_reader :results, :id
  TREE_NODE_JOIN = 'left outer join tree_node tnode on name.id = tnode.name_id'
  FOR_TNODE = ' on tnode.tree_arrangement_id = ta.id'
  SHARD_TREE_LABEL = "select value from shard_config where name = 'tree label'"
  FOR_TREE_LABEL = "and ta.label = (#{SHARD_TREE_LABEL})"
  LEFT_OUTER_JOIN = 'left outer join tree_arrangement ta '
  TREE_JOIN = "#{LEFT_OUTER_JOIN} #{FOR_TNODE} #{FOR_TREE_LABEL}"

  def initialize(name_id)
    Rails.logger.debug('Name::Search::UsageQuery initialize')
    @id = name_id
    build_query
  end

  def build_query
    Rails.logger.debug('Name::Search::UsageQuery.build_query')
    Rails.logger.debug('Name::Search::UsageQuery start ====================')
    @results = Name.where(id: @id)
                   .joins(instances: [:instance_type, reference: :author])
                   .joins(TREE_NODE_JOIN)
                   .joins(TREE_JOIN)
                   .select(columns)
                   .group(grouping)
                   .order(ordering)

    Rails.logger.debug("@results.inspect: #{@results.inspect} ====================")
    Rails.logger.debug('Name::Search::UsageQuery end   ====================')
  end

  def columns
    "name.id name_id,name.full_name, name.full_name_html, \
    reference.id reference_id, reference.year reference_year, instance_type.id,\
    instance_type.name instance_type_name, instance_type.misapplied, author.id,\
    reference.citation_html,coalesce(reference.year,9999), author.name,  \
    primary_instance, instance.id instance_id, instance.page instance_page, \
    instance.page_qualifier instance_page_qualifier, \
    reference.citation reference_citation, max(case when instance.id = \
    tnode.instance_id and tnode.next_node_id is null and \
    tnode.checked_in_at_id is not null and instance_id = tnode.instance_id \
    then tnode.type_uri_id_part else '' end) accepted_tree_status"
  end

  def grouping
    "name.id, name.full_name, reference.id, reference.year, instance_type.id, \
    instance_type.name, instance_type.misapplied,
    author.id,reference.citation_html,coalesce(reference.year,9999),  \
    author.name, primary_instance, instance.id, instance.page, \
    instance.page_qualifier, reference.citation " 
  end

  def ordering
    'coalesce(reference.year,9999), primary_instance desc, author.name'
  end
end
