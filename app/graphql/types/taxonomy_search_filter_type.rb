# frozen_string_literal: true

class Types::TaxonomySearchFilterType < Types::BaseInputObject
  description 'SearchFilterType'
  argument :searchTerm, String, required: true
  argument :acceptedNames, Boolean, required: false
  argument :excludedNames, Boolean, required: false
  argument :crossReferences, Boolean, required: false
  argument :id, Int, required: false
end
