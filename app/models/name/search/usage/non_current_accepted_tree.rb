# frozen_string_literal: true

# Provide accepted tree details for a name from a name usage query record.
# Allow for raw data to be passed on from the name usage query record,
# but also allow for wrapped or otherwise processed data.
#
# Assumes a non-current accepted tree element has been found.
class Name::Search::Usage::NonCurrentAcceptedTree
  def initialize(name_usage_query_record)
    @name_usage_query_record = name_usage_query_record
    tree_element = TreeElement.find_by(instance_id: @name_usage_query_record.instance_id)
    debug("tree_element.profile: #{tree_element.profile}")
    debug("tree_element.profile.class: #{tree_element.profile.class}")
    #@parsed_components = ParsedComponents.new(name_usage_query_record, '')
    @parsed_components = ParsedComponents.new(name_usage_query_record, tree_element.profile)
  end

  def debug(s)
    Rails.logger.debug("Name::Search::Usage::NonCurrentAcceptedTreeDetails: #{s}")
  end

  def details
    atd = OpenStruct.new
    atd.comment = Comment.new(@parsed_components).content
    atd.distribution = Distribution.new(@parsed_components).content
    atd
  end
end
