# frozen_string_literal: true

# Rails model for Tree Element
# A tree element is a node on a taxonomic tree version
class TreeElement < ApplicationRecord
  self.table_name = 'tree_element'
  self.primary_key = 'id'
  belongs_to :name
  belongs_to :instance
  has_many :tree_version_elements

  def distribution_value
    profile[distribution_key]["value"]
  end

  def distribution?
    distribution_key.present?
  end

  def distribution_key
    profile_key(/Dist/)
  end

  def comment?
    comment_key.present?
  end

  def comment_key
    profile_key(/Comment/)
  end

  def comment_value
    profile[comment_key]["value"]
  end

  def profile_value(key_string)
    key = profile_key(key_string)
    if key
      profile[key]["value"]
    else
      ""
    end
  end

  def profile_key(key_string)
    profile.keys.find { |key| key_string == key } if profile.present?
  end
end
