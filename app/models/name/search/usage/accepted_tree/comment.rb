# frozen_string_literal: true

# Provide accepted tree comment for a name from a name usage query record.
#
# Assumes a tree element has been found.
class Name::Search::Usage::AcceptedTree::Comment
  def initialize(parsed_components)
    @parsed_components = parsed_components
    @tree_config = @parsed_components.tree_config
  end

  def content
    return nil unless accepted_tree_comment?

    cstruct = OpenStruct.new
    cstruct.key = accepted_tree_comment_label
    cstruct.value = accepted_tree_comment
    cstruct
  end

  private

  def accepted_tree_comment
    return nil if @parsed_components.profile.blank?
    return nil if @parsed_components.profile['APC Comment'].blank?

    @parsed_components.profile['APC Comment']['value']
  end

  def accepted_tree_comment_label
    config = @tree_config[:tree_element_config]
    return nil if config.nil?

    config['comment_key']
  end

  def accepted_tree_comment?
    !accepted_tree_comment.blank?
  end

  def debug(msg)
    prefix = 'Name::Search::Usage::AcceptedTreeDetails::Comment'
    Rails.logger.debug("#{prefix}: #{msg}")
  end
end
