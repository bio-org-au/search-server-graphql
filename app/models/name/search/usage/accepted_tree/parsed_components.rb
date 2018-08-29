# frozen_string_literal: true

# Provide parsed json components.
# Assumes a tree element has been found.
class Name::Search::Usage::AcceptedTree::ParsedComponents
  def initialize(name_usage_query_record)
    @name_usage_query_record = name_usage_query_record
  end

  def debug(message)
    prefix = 'Name::Search::Usage::AcceptedTree::ParsedComponents'
    for_instance = "for instance id #{@name_usage_query_record.try('instance_id')}"
    Rails.logger.debug("#{prefix} #{for_instance}: #{message}")
  end

  def profile
    return nil if @name_usage_query_record.tree_element_profile.blank?
    @name_usage_query_record.tree_element_profile
  end

  def tree_config
    @tree_config ||= @name_usage_query_record.tree_config
  end
end
