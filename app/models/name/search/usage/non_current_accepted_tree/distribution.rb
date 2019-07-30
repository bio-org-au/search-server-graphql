# frozen_string_literal: true

# Provide non current accepted tree distribution for a name from a name usage query record.
#
# Assumes a tree element has been found.
class Name::Search::Usage::NonCurrentAcceptedTree::Distribution
  def initialize(parsed_components)
    @parsed_components = parsed_components
  end

  def debug(s)
    prefix = 'Name::Search::Usage::NonCurrentAcceptedTreeDetails::Distribution'
    Rails.logger.debug("#{prefix}: #{s}")
  end

  def content
    #return nil unless accepted_tree_distribution?
    struct = OpenStruct.new
    struct.key = accepted_tree_distribution_label
    struct.value = accepted_tree_distribution
    struct
  end

  def accepted_tree_distribution
    return nil if @parsed_components.profile.blank?
    return nil if @parsed_components.profile['APC Dist.'].blank?
    @parsed_components.profile['APC Dist.']['value']
  end

  def accepted_tree_distribution_label
    '' #@parsed_components.tree_config['distribution_key']
  end

  def accepted_tree_distribution?
    return true if accepted_tree_distribution.present?
    true
  end

  def xaccepted_tree_distribution?
    !accepted_tree_distribution.blank?
  end
end
