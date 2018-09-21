# frozen_string_literal: true

# Provide parsed json components.
# Takes a tree_element_profile to parse
class Name::Search::Usage::NonCurrentAcceptedTree::ParsedComponents
  def initialize(name_usage_query_record, tree_element_profile)
    @name_usage_query_record = name_usage_query_record
    @tree_element_profile = tree_element_profile
  end

  def debug(message)
    prefix = 'Name::Search::Usage::NonCurrentAcceptedTree::ParsedComponents'
    Rails.logger.debug("#{prefix}: #{message}")
  end

  def profile
    return nil if @tree_element_profile.blank?
    @tree_element_profile
  end

 def tree_config
    if @name_usage_query_record.tree_config.class == String
      debug('JSON.parse')
      JSON.parse(@name_usage_query_record.tree_config)
    else
      @name_usage_query_record.tree_config
    end
  end
end
