# frozen_string_literal: true

class Types::TaxonomicNameUsageFilterType < Types::BaseInputObject
  description 'TaxonomicNameUsageFilterType'
  argument :name, String, required: true
  argument :taxonomicStatus, String, required: false
  argument :nomenclaturalStatus, NomenclaturalStatusEnum, required: false
  argument :taxonomicNameUsageType, TaxonomicStatusEnum, required: false
  argument :protonym, Boolean, required: false
  argument :primary, Boolean, required: false
  argument :newTaxon, Boolean, required: false
  argument :newCombination, Boolean, required: false
  argument :newName, Boolean, required: false
  argument :newStatus, Boolean, required: false
  argument :autonym, Boolean, required: false
end

