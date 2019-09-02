# frozen_string_literal: true

# Provide parsed json components.
# Assumes a tree element has been found.
class Name::Search::Usage::AcceptedTree::ParsedComponents
  def initialize(tree_info)
    debug('initialize')
    debug("tree_info.inspect: #{tree_info.inspect}")
    @tree_info = tree_info
  end

  def debug(message)
    Rails.logger.debug("Name::Search::Usage::AcceptedTree::ParsedComponents: #{message}")
    # prefix = 'Name::Search::Usage::AcceptedTree::ParsedComponents'
    # for_instance = "for instance id #{@tree_info[:tree_element_instance_id]}"
    # Rails.logger.debug("#{prefix} #{for_instance}: #{message}")
  end

  def profile
    debug('profile start')
    debug("profile: #{@tree_info[:tree_element_profile]}")
    return nil if @tree_info[:tree_element_profile].blank?

    debug('non-blank profile, so continuing')
    debug(@tree_info[:tree_element_profile].inspect)
    debug("class: #{@tree_info[:tree_element_profile].class}")
    if @tree_info[:tree_element_profile].class == String
      debug('JSON.parse')
      JSON.parse(@tree_info[:tree_element_profile])
    else
      @tree_info[:tree_element_profile]
    end
  end

  def tree_config
    debug("tree_element_config class: #{@tree_info[:tree_element_config].class}")
    debug("tree_element_config inspect: #{@tree_info[:tree_element_config].inspect}")
    if @tree_info[:tree_element_config].class == String
      debug('parsing tree_element_config')
      JSON.parse(@tree_info[:tree_element_config])
    else
      debug('not parsing tree_element_config')
      @tree_info[:tree_element_config]
      @tree_info
    end
  end
end
