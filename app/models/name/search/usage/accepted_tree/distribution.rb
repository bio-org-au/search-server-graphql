# frozen_string_literal: true

# Provide accepted tree distribution for a name from a name usage query record.
#
# Assumes a tree element has been found.
class Name::Search::Usage::AcceptedTree::Distribution
  def initialize(parsed_components)
    debug('initialize')
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
    struct.key = accepted_tree_distribution_key
    struct.value = accepted_tree_distribution
    debug(struct.inspect)
    struct
  end

  def accepted_tree_distribution
    debug('accepted_tree_distribution start')
    profile = @parsed_components.profile
    dist_key = accepted_tree_distribution_key
    debug("dist_key: #{dist_key}")
    return nil if profile.blank?
    debug('accepted_tree_distribution continuing 1 - profile is not blank')
    debug("profile.inspect: #{profile.inspect}")
    debug("class: #{profile.class}")
    if profile[dist_key].blank?
      debug("profile[#{dist_key}] is blank!")
    end
    return nil if profile[dist_key].blank?
    debug("accepted_tree_distribution continuing 2 - profile[#{dist_key}] is NOT blank")
    debug(profile[dist_key])
    debug("accepted_tree_distribution continuing 3: #{profile[dist_key]['value']}.inspect")
    profile[dist_key]['value']
  end

  def accepted_tree_distribution_key
    @parsed_components.tree_config['distribution_key']
  end

  def accepted_tree_distribution?
    !accepted_tree_distribution.blank?
  end
end
