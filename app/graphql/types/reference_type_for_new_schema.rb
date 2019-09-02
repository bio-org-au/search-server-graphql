# frozen_string_literal: true

Types::ReferenceTypeForNewSchema = GraphQL::ObjectType.define do
  name 'Reference'
  field :id, !types.ID, property: :uri
  field :author, !Types::AuthorType, property: :author
  field :citation, types.String
  # field :shortRef: String
  # field :displayTitle: String
  field :doi, types.String
  field :edition, types.String
  # """
  # Instances for a reference. For references only standalone instances are
  # provided.
  # """
  # field :instances: [TaxonomicNameUsage!]! @paginate(type: "paginator")
  field :isbn, types.String
  field :issn, types.String
  field :pages, types.String
  field :parent, Types::ReferenceTypeForNewSchema
  field :publicationDate, types.String, property: :iso_publication_date
  field :published, !types.Boolean, property: :published?
  field :publishedLocation, types.String, property: :published_location
  field :publisher, types.String
  field :refAuthorRole, !Types::RefAuthorRoleType, property: :ref_author_role
  field :refType, !Types::RefTypeType, property: :ref_type
  field :title, !types.String
  field :tl2, types.String
  field :uri, types.String
  field :verbatimAuthor, types.String, property: :verbatim_author
  field :volume, types.String
  field :year, types.Int
end

#
#        Column        |           Type           |                      Modifiers
# ----------------------+--------------------------+------------------------------------------------------
#  id                   | bigint                   | not null default nextval('nsl_global_seq'::regclass)
#  lock_version         | bigint                   | not null default 0
#  abbrev_title         | character varying(2000)  |
#  author_id            | bigint                   | not null
#  bhl_url              | character varying(4000)  |
#  citation             | character varying(4000)  |
#  citation_html        | character varying(4000)  |
#  created_at           | timestamp with time zone | not null
#  created_by           | character varying(255)   | not null
#  display_title        | character varying(2000)  | not null
#  doi                  | character varying(255)   |
#  duplicate_of_id      | bigint                   |
#  edition              | character varying(100)   |
#  isbn                 | character varying(16)    |
#  issn                 | character varying(16)    |
#  language_id          | bigint                   | not null
#  namespace_id         | bigint                   | not null
#  notes                | character varying(1000)  |
#  pages                | character varying(1000)  |
#  parent_id            | bigint                   |
#  publication_date     | character varying(50)    |
#  published            | boolean                  | not null default false
#  published_location   | character varying(1000)  |
#  publisher            | character varying(1000)  |
#  ref_author_role_id   | bigint                   | not null
#  ref_type_id          | bigint                   | not null
#  source_id            | bigint                   |
#  source_id_string     | character varying(100)   |
#  source_system        | character varying(50)    |
#  title                | character varying(2000)  | not null
#  tl2                  | character varying(30)    |
#  updated_at           | timestamp with time zone | not null
#  updated_by           | character varying(1000)  | not null
#  valid_record         | boolean                  | not null default false
#  verbatim_author      | character varying(1000)  |
#  verbatim_citation    | character varying(2000)  |
#  verbatim_reference   | character varying(1000)  |
#  volume               | character varying(100)   |
#  year                 | integer                  |
#  uri                  | text                     |
#  iso_publication_date | character varying(10)    |
