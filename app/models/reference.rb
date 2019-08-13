# frozen_string_literal: true

# Rails model
class Reference < ActiveRecord::Base
  include PgSearch
  self.table_name = 'reference'
  self.primary_key = 'id'
  belongs_to :author
  belongs_to :language
  belongs_to :namespace
  belongs_to :ref_author_role, foreign_key: 'ref_author_role_id'
  belongs_to :ref_type
  # belongs_to :reference_author, class_name: :author
  belongs_to :parent, class_name: Reference, foreign_key: 'parent_id'
  has_many :children,
           class_name: 'Reference',
           foreign_key:  'parent_id',
           dependent: :restrict_with_exception

  # acts_as_tree foreign_key: :duplicate_of_id, order: "title"
  # Cannot have 2 acts_as_tree in one model.
  belongs_to :duplicate_of,
             class_name: 'Reference',
             foreign_key: 'duplicate_of_id'
  has_many :duplicates,
           class_name: 'Reference',
           foreign_key: 'duplicate_of_id',
           dependent: :restrict_with_exception

  has_many :instances, foreign_key: 'reference_id'
  has_many :name_instances,
           -> { where 'cited_by_id is not null' },
           class_name: 'Instance',
           foreign_key: 'reference_id'

  # https://github.com/Casecommons/pg_search
  # https://content.pivotal.io/blog/pg-search-how-i-learned-to-stop-
  # worrying-and-love-postgresql-full-text-search
  PgSearch.unaccent_function = 'f_unaccent'
  pg_search_scope :search_citation_text_for,
                  against: :citation,
                  ignoring: :accents,
                  using: {
                    tsearch: {
                      dictionary: 'english',
                      prefix: 'true',
                    }
                  }
  def author_string_and_year
    citation.sub(/\),.*/,')')
  end

  def uri
    "#{Cache::MAPPER_HOST}reference/#{Cache::NAME_SPACE.downcase}/#{id}"
  end
end
