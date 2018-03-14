# frozen_string_literal: true

# String methods
module SearchableNameStrings
  refine String do
    # Convert 
    # - star to regex wildcard
    # - percent to regex wildcard
    # Add top and tail anchors.
    # Treat matching inverted commas as general quoting characters
    def regexified
      gsub("*", ".*").gsub("%", ".*").sub(/$/, "$").sub(/^/, "^") 
      #.gsub(/[‘’]/,%q(["‘''’])) # only works the first time after "compiling"
      # a change!
    end

    # Allow for hybrids even if the user doesn't
    def hybridized
      strip.gsub(/  */, " (x )?").sub(/^ */, "(x )?").tr("×", "x")
    end
  end
end

# Name model
class Name < ApplicationRecord
  using SearchableNameStrings
  SIMPLE_NAME_REGEX =
    'lower(f_unaccent(simple_name)) ~ lower(f_unaccent(?)) '
  FULL_NAME_REGEX =
    'lower(f_unaccent(full_name)) ~ lower(f_unaccent(?))'
  self.table_name = 'name'
  self.primary_key = 'id'
  belongs_to :name_type
  belongs_to :name_rank, class_name: 'NameRank', foreign_key: 'name_rank_id'
  belongs_to :status, class_name: 'NameStatus', foreign_key: 'name_status_id'
  belongs_to :name_status
  belongs_to :author
  belongs_to :namespace
  belongs_to :author
  belongs_to :ex_author, class_name: 'Author'
  belongs_to :base_author, class_name: 'Author'
  belongs_to :ex_base_author, class_name: 'Author'
  belongs_to :sanctioning_author, class_name: 'Author'
  belongs_to :parent, class_name: 'Name', foreign_key: 'parent_id'
  has_many :children,
           class_name: 'Name',
           foreign_key: 'parent_id',
           dependent: :restrict_with_exception
  belongs_to :second_parent,
             class_name: 'Name', foreign_key: 'second_parent_id'
  has_many :second_children,
           class_name: 'Name',
           foreign_key: 'second_parent_id',
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
  belongs_to :duplicate_of, class_name: 'Name', foreign_key: 'duplicate_of_id'
  has_many :duplicates,
           class_name: 'Name',
           foreign_key: 'duplicate_of_id',
           dependent: :restrict_with_exception # , order: 'name_element'
  has_one :accepted_name, foreign_key: 'id'
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

  scope :name_matches, (lambda do |string|
    where("#{SIMPLE_NAME_REGEX} or #{FULL_NAME_REGEX}",
          string.hybridized.regexified.gsub(/[‘’]/,%q(["‘''’])),
          string.hybridized.regexified.gsub(/[‘’]/,%q(["‘''’]))
         )
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

  # This generates one select per record and I cannot
  # find a way to eliminate that select using an includes
  # clause.  But name_tree_path will be eliminated in the
  # forthcoming tree changes.
  def family_name
    name_tree_paths.first.try('family').try('full_name')
  end

  # Expensive, see above.
  def family_name_id
    name_tree_paths.first.try('family').try('id')
  end

  def name_status_name
    name_status.name
  end

  def name_rank_name
    name_rank.name
  end

  # Use a protected method to apply bind variables to a sql string
  # safely.
  #
  # See answer by GeorgeBrock here:
  # https://stackoverflow.com/questions/13062623/
  #   activerecord-select-with-parameter-binding
  #
  # Example use:
  # ActiveRecord::Base.connection.select_all(Name.select_with_args('select
  # simple_name,nt.name from name join name_type nt on name.name_type_id = nt.id
  # where name.id = ?',91755))
  def self.select_with_args(sql, args)
    sanitize_sql_array([sql, args].flatten)
  end

  def accepted_tree_status
    "Don't look here"
  end

  def accepted?
    accepted_name.present? && accepted_name.accepted_accepted?
  end

  def excluded?
    accepted_name.present? && accepted_name.accepted_excluded?
  end

  def author_component_of_full_name
    full_name.sub(/#{Regexp.escape(simple_name)}/, "")
  end

  def check_name(name)
    Name.where(["lower(simple_name) like ? or lower(full_name) like ?", name, name])
  end
end
