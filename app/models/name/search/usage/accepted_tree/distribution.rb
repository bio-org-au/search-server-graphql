# frozen_string_literal: true

# Provide accepted tree distribution for a name from a name usage query record.
#
# Assumes a tree element has been found.
class Name::Search::Usage::AcceptedTree::Distribution
  def initialize(parsed_components)
    @parsed_components = parsed_components
  end

  def debug(s)
    prefix = 'Name::Search::Usage::AcceptedTreeDetails::Distribution'
    for_instance = "for instance id #{@parsed_components.try('instance_id')}"
    Rails.logger.debug("#{prefix} #{for_instance}: #{s}")
  end

  def content
    debug('content start')
    return nil unless accepted_tree_distribution?
    debug('content start continuing')
    struct = OpenStruct.new
    struct.key = accepted_tree_distribution_label
    struct.value = accepted_tree_distribution
    debug(struct.inspect)
    struct
  end

  def accepted_tree_distribution
    debug('accepted_tree_distribution')
    return nil if @parsed_components.profile.blank?
    debug('accepted_tree_distribution continuing 1 - profile is not blank')
    return nil if @parsed_components.profile['APC Dist.'].blank?
    debug("accepted_tree_distribution continuing 2 - profile['APC Dist.'] is not blank")
    debug("accepted_tree_distribution continuing 3: #{@parsed_components.profile['APC Dist.']['value']}")
    @parsed_components.profile['APC Dist.']['value']
  end

  def accepted_tree_distribution_label
    @parsed_components.tree_config['distribution_key']
  end

  def accepted_tree_distribution?
    !accepted_tree_distribution.blank?
  end
end
