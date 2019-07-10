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
      gsub("*", ".*").gsub("%", ".*").sub(/^/, "^") 
      #gsub("*", ".*").gsub("%", ".*").sub(/$/, "$").sub(/^/, "^") 
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
  FULL_NAME_REGEX =
    'lower(f_unaccent(name.full_name)) ~ lower(f_unaccent(?))'
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
  belongs_to :family, class_name: 'Name', foreign_key: 'family_id'
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
  has_many :instances
  has_many :instance_types, through: :instances
  has_many :instance_notes
  has_many :references, through: :instances
  has_many :reference_authors, through: :references, class_name: 'Author'
  has_many :tree_elements
  belongs_to :duplicate_of, class_name: 'Name', foreign_key: 'duplicate_of_id'
  has_many :duplicates,
           class_name: 'Name',
           foreign_key: 'duplicate_of_id',
           dependent: :restrict_with_exception # , order: 'name_element'
  has_one :accepted_name, foreign_key: 'id'
  scope :not_a_duplicate, -> { where(duplicate_of_id: nil) }
  scope :ordered_by_sort_name_and_rank, (lambda do
                                    order("name.sort_name, name_rank.sort_order")
                                  end)
  scope :has_an_instance, (lambda do
    where(["exists (select null
           from instance
           where name.id = instance.name_id)"])
  end)

  scope :name_matches, (lambda do |string|
    where("#{FULL_NAME_REGEX}",
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

  def self.search_for_id(id)
    debug("search_for_id: #{id}")
    results = Name.where(id: id)
    if results.blank?
      empty_record_object
    else
      results.first
    end
  end

  def self.empty_record_object
    obj = OpenStruct.new
    obj.id = nil
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

  def name_usages
    debug('name_usages')
    Name::Search::Usages.new(id).name_usages
  end

  def family_name
    return nil if family.nil?
    family.full_name
  end

  def name_status_name
    name_status.name
  end

  def name_status_is_displayed
    name_status.show?
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
    tree_element = Tree.accepted.first.current_tree_version.tree_elements.where(name_id: self.id).first
    tree_element.present? && tree_element.excluded == false
  end

  def excluded?
    tree_element = Tree.accepted.first.current_tree_version.tree_elements.where(name_id: self.id).first
    tree_element.present? && tree_element.excluded == true
  end

  def author_component_of_full_name
    full_name.sub(/#{Regexp.escape(simple_name)}/, "")
  end

  def check_name(name)
    Name.where(["lower(simple_name) like ? or lower(full_name) like ?", name, name])
  end

  def self.run_union_search(union_condition, order_string = '1', limit = 500, offset = 0)
    table_alias = arel_table.create_table_alias(union_condition, arel_table.name)
    from(table_alias).order(order_string).limit(limit).offset(offset)
  end

  def images
    # TODO: use self not id - self did not contain name_rank_id
    Name::Images.new(id).results
  end

  private

  def self.debug(s)
    Rails.logger.debug("==============================================")
    Rails.logger.debug("Model Name: #{s}")
    Rails.logger.debug("==============================================")
  end

  def debug(s)
    Rails.logger.debug("==============================================")
    Rails.logger.debug("Model Name: #{s}")
    Rails.logger.debug("==============================================")
  end
end
