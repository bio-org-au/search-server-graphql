# frozen_string_literal: true

# Name model
class Name < ApplicationRecord
  include NameSearchable
  self.table_name = 'name'
  self.primary_key = 'id'
  belongs_to :name_type
  belongs_to :name_rank, class_name: 'NameRank', foreign_key: 'name_rank_id'
  belongs_to :status, class_name: 'NameStatus', foreign_key: 'name_status_id'
  belongs_to :name_status
  belongs_to :author
  belongs_to :namespace
  belongs_to :author
  belongs_to :ex_author, class_name: "Author"
  belongs_to :base_author, class_name: "Author"
  belongs_to :ex_base_author, class_name: "Author"
  belongs_to :sanctioning_author, class_name: "Author"
  belongs_to :parent, class_name: "Name", foreign_key: "parent_id"
  has_many :children,
           class_name: "Name",
           foreign_key: "parent_id",
           dependent: :restrict_with_exception
  belongs_to :second_parent,
             class_name: "Name", foreign_key: "second_parent_id"
  has_many :second_children,
           class_name: "Name",
           foreign_key: "second_parent_id",
           dependent: :restrict_with_exception
  has_many :name_tree_paths
  has_many :ntp_children, class_name: 'NameTreePath', foreign_key: 'family_id'
  has_one  :name_tree_path_default
  has_one  :taxonomy_name_tree_path, class_name: 'NameTreePath'
  has_many :instances
  has_many :instance_types, through: :instances
  has_many :instance_notes
  has_many :references, through: :instances
  has_many :reference_authors, through: :references, class_name: 'Author'
  has_many :tree_nodes
  belongs_to :duplicate_of, class_name: "Name", foreign_key: "duplicate_of_id"
  has_many :duplicates,
           class_name: "Name",
           foreign_key: "duplicate_of_id",
           dependent: :restrict_with_exception # , order: 'name_element'
  scope :not_a_duplicate, -> { where(duplicate_of_id: nil) }
  scope :ordered_scientifically, (lambda do
                                    order("coalesce(trim( trailing '>'
                                          from substring(substring(
                                          name_tree_path.rank_path from
                                          'Familia:[^>]*>') from 9)),
                                          'A'||to_char(name_rank.sort_order,
                                          '0009')), sort_name,
                                          name_rank.sort_order")
                                  end)
  scope :has_an_instance, (lambda do
    where(["exists (select null
           from instance
           where name.id = instance.name_id)"])
  end)

  def self.scientific_search
    Name.not_a_duplicate
        .has_an_instance
        .joins(:name_types)
        .includes(:status)
        .includes(:rank)
  end

  def full_name_html_with_status
    if status.show?
      "#{full_name_html}#{status.name_to_show}"
    else
      full_name_html
    end
  end

  def full_name_with_status
    if status.show?
      "#{full_name}#{status.name_to_show}"
    else
      full_name
    end
  end

  def images_supported?
    Rails.configuration.try('image_links_supported') || false
  end

  def name_history
    Name::Search::History.new(id)
  end

  def family_name
    if name_type.scientific? || name_type.cultivar?
      return "na" if name_rank.family_or_above?
      family_id = (NameTreePath.where(name_id: id).where(tree_id: TreeArrangement.default_name_tree_id).first.family_id)
      return "na" if family_id.blank?
      Name.find(family_id).full_name
    else
      "na"
    end
  rescue
    "Problem finding family for name: #{id}"
  end

  def name_status_name
    name_status.name
  end
end
