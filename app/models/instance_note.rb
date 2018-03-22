# frozen_string_literal: true

# Rails model
class InstanceNote < ActiveRecord::Base
  self.table_name = 'instance_note'
  self.primary_key = 'id'

  belongs_to :instance
  belongs_to :instance_note_key
  # belongs_to :name_detail, foreign_key: "instance_id"

  scope :without_type_notes, (lambda do
    where("instance_note_key_id not in
          (select id from instance_note_key
          where name in ('Lectotype', 'Neotype','Type') ) ")
  end)

  scope :without_epbc_notes, (lambda do
    where("instance_note_key_id not in
          (select id from instance_note_key
          where name like 'EPBC%') ")
  end)

  scope :not_deprecated, (lambda do
    where("instance_note_key_id not in
          (select id from instance_note_key
          where deprecated) ")
  end)

  scope :ordered_for_display, (lambda do
                                 order('id asc')
                               end)

  def accepted_tree_distribution?
    instance_note_key.accepted_tree_distribution?
  end

  def accepted_tree_comment?
    instance_note_key.accepted_tree_comment?
  end

  def marked_up_value
    value.gsub(/<IT>/, '<em>').gsub(/<RO>/, '</em> ')
  end

  def key
    instance_note_key.name
  end
end
