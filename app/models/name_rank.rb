# frozen_string_literal: true

# Rails model
class NameRank < ActiveRecord::Base
  self.table_name = 'name_rank'
  self.primary_key = 'id'
  has_many :names
  has_many :name_or_synonyms
  belongs_to :name_group

  def self.species
    find_by(name: 'Species')
  end

  def self.family
    find_by(name: 'Familia')
  end

  def show?
    !visible_in_name && above_species?
  end

  def above_species?
    sort_order < NameRank.species.sort_order
  end

  def species_or_below?
    !above_species?
  end

  def family_or_above?
    sort_order <= NameRank.family.sort_order
  end

  def self.above_species?(rank_sort_order)
    rank_sort_order < NameRank.species.sort_order
  end

  def self.show?(_rank_name, rank_visible_in_name, rank_sort_order)
    !rank_visible_in_name && NameRank.above_species?(rank_sort_order)
  end
end
