class Name < ApplicationRecord
  include NameSearchable
  self.table_name = 'name'
  self.primary_key = 'id'
  belongs_to :name_type
  belongs_to :name_rank, class_name: 'NameRank', foreign_key: 'name_rank_id'
  belongs_to :status, class_name: 'NameStatus', foreign_key: 'name_status_id'
  belongs_to :name_status
  has_many :name_tree_paths
  has_one  :name_tree_path_default
  has_many :instances
  has_many :instance_types, through: :instances
  has_many :instance_notes
  has_many :references, through: :instances
  has_many :reference_authors, through: :references, class_name: 'Author'
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
    NameHistory.new(id)
  end
end
