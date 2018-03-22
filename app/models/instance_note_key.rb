# frozen_string_literal: true

# Rails model
class InstanceNoteKey < ActiveRecord::Base
  self.table_name = 'instance_note_key'
  self.primary_key = 'id'

  has_many :instance_notes
  has_many :instance_note_for_distributionss
  has_many :instance_note_for_type_specimens
  has_many :instance_notes_for_details

  def accepted_tree_comment?
    name.match(/#{ShardConfig.tree_label} Comment/)
  end

  def accepted_tree_distribution?
    name.match(/#{ShardConfig.tree_label} Dist./)
  end
end
