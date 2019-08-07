# frozen_string_literal: true

# Provide accepted tree details for a name from a name usage query record.
# Allow for raw data to be passed on from the name usage query record,
# but also allow for wrapped or otherwise processed data.
#
# Assumes a tree element has been found.
class Name::Search::Usage::AcceptedTree
  def initialize(tree_info)
    @tree_info = tree_info
    debug("tree_info.inspect: #{tree_info.inspect}")
    @parsed_components = ParsedComponents.new(@tree_info)
  end

  def debug(s)
    Rails.logger.debug("Name::Search::Usage::AcceptedTree: for instance id #{@tree_info[:tree_element_instance_id]}: #{s}")
  end

  def details
    atd = OpenStruct.new
    atd.is_accepted = accepted_in_accepted_tree?
    atd.is_excluded = excluded_from_accepted_tree?
    atd.comment = Comment.new(@parsed_components).content
    atd.distribution = Distribution.new(@parsed_components).content
    atd
  end

  def accepted_in_accepted_tree?
    @tree_info[:accepted]
  end

  def excluded_from_accepted_tree?
    @tree_info[:excluded]
  end
end
