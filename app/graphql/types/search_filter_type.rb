# frozen_string_literal: true

class Types::SearchFilterType < Types::BaseInputObject
  description 'SearchFilterType'
  argument :searchTerm, String, required: false
  argument :authorAbbrev, String, required: false
  argument :exAuthorAbbrev, String, required: false
  argument :baseAuthorAbbrev, String, required: false
  argument :exBaseAuthorAbbrev, String, required: false
  argument :family, String, required: false
  argument :genus, String, required: false
  argument :species, String, required: false
  argument :rank, String, required: false
  argument :includeRanksBelow, Boolean, required: false
  argument :publication, String, required: false
  argument :isoPublicationDate, String, required: false
  argument :protologue, String, required: false
  argument :nameElement, String, required: false
  argument :typeOfName, String, required: false
  argument :scientificName, Boolean, required: false
  argument :scientificAutonymName, Boolean, required: false
  argument :scientificNamedHybridName, Boolean, required: false
  argument :scientificHybridFormulaName, Boolean, required: false
  argument :cultivarName, Boolean, required: false
  argument :commonName, Boolean, required: false
  argument :typeNoteText, String, required: false
  argument :typeNoteKeys, [String], required: false
  argument :orderByName, Boolean, required: false
end
