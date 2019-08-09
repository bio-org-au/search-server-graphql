# https://github.com/rmosolgo/graphql-ruby/blob/master/guides/type_definitions/enums.md
class Types::TaxonomicStatusEnum < Types::BaseEnum
  value "ACCEPTED",                           "Accepted"
  value "EXCLUDED",                           "Excluded"
end
