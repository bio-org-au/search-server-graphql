# frozen_string_literal: true

# Provide accepted tree distribution for a name from a name usage query record.
#
# Assumes a tree element has been found.
#
# Example data:
#
# {:accepted=>true,
#  :excluded=>false,
#  :tree_element_id=>51230780,
#  :tree_element_instance_id=>612278,
#  :tree_element_profile=>{"APC Dist."=>{"value"=>"Qld, NSW, Vic)",
#                          "created_at"=>"2009-09-28T00:00:00+10:00",
#                          "created_by"=>"BLEPSCHI",
#                          "updated_at"=>"2009-09-28T00:00:00+10:00",
#                          "updated_by"=>"BLEPSCHI",
#                          "source_link"=>
#                 "https://id.biodiversity.org.au/instanceNote/apni/1105780"}},
#  :tree_element_config=>{"comment_key"=>"APC Comment",
#                         "distribution_key"=>"APC Dist."}
# }
#
class Name::Search::Usage::AcceptedTree::Distribution
  def initialize(parsed_components)
    @parsed_components = parsed_components
    @profile = parsed_components.profile
    @tree_config = @parsed_components.tree_config
  end

  def content
    return nil unless accepted_tree_distribution?

    struct = OpenStruct.new
    struct.key = distribution_key
    struct.value = accepted_tree_distribution
    struct
  end

  private

  # From tree_config, get to the distribution key.
  #
  #  :tree_element_config=>{"comment_key"=>"APC Comment",
  #                         "distribution_key"=>"APC Dist."}
  def distribution_key
    config = @tree_config[:tree_element_config]
    return nil if config.nil?

    config['distribution_key']
  end

  def accepted_tree_distribution?
    !accepted_tree_distribution.blank?
  end

  # From tree_config get the distribution using the configured distribution key
  # (which can vary across shards).
  #
  #  :tree_element_profile=>{"APC Dist."=>{"value"=>"Qld, NSW, Vic",
  #
  def accepted_tree_distribution
    return nil if @profile.blank?

    @profile[distribution_key]['value']
  end

  def debug(msg)
    prefix = 'Name::Search::Usage::AcceptedTreeDetails::Distribution'
    for_instance = "for instance id #{@parsed_components.try('instance_id')}"
    Rails.logger.debug("#{prefix} #{for_instance}: #{msg}")
  end
end
