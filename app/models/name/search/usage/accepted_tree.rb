# frozen_string_literal: true

# Provide accepted tree details for a name from a name usage query record.
# Allow for raw data to be passed on from the name usage query record,
# but also allow for wrapped or otherwise processed data.
#
# Assumes a tree element has been found.
class Name::Search::Usage::AcceptedTree
  def initialize(name_usage_query_record)
    @name_usage_query_record = name_usage_query_record
    @parsed_components = ParsedComponents.new(name_usage_query_record)
  end

  def debug(s)
    Rails.logger.debug("Name::Search::Usage::AcceptedTreeDetails: #{s}")
  end

  def details
    atd = OpenStruct.new
    atd.is_accepted = accepted_in_accepted_tree?
    atd.is_excluded = excluded_from_accepted_tree?
    atd.comment = Comment.new(@parsed_components).content
    atd.distribution = Distribution.new(@parsed_components).content
    #atd.distribution = { "key": "APC Dist.", "value": "xzyxyz" }
    atd
  end

  def accepted_in_accepted_tree?
    @name_usage_query_record.tree_element_excluded == 'f'
  end

  def excluded_from_accepted_tree?
    @name_usage_query_record.tree_element_excluded == 't'
  end
end
