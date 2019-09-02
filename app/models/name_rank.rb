# frozen_string_literal: true

# Rails model
class NameRank < ActiveRecord::Base
  self.table_name = 'name_rank'
  self.primary_key = 'id'
  has_many :names
  has_many :name_or_synonyms
  belongs_to :name_group
  has_many :children, class_name: 'NameRank', foreign_key: :parent_rank_id
  belongs_to :parent_rank, class_name: 'NameRank'

  def self.species
    find_by(name: 'Species')
  end

  def self.genus
    find_by(name: 'Genus')
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

  def options
    NameRank.all.order(:sort_order).where('not deprecated').map(&:name)
  end

  def species?
    sort_order == NameRank.species.sort_order
  end

  def parent?
    !parent_rank_id.nil?
  end

  def below_species?
    sort_order > NameRank.species.sort_order
  end

  def below_genus?
    sort_order > NameRank.genus.sort_order
  end

  def genus_or_above?
    !below_genus?
  end

  def infra_generic?
    above_species? && below_genus?
  end
end
