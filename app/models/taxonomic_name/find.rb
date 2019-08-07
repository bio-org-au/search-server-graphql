# frozen_string_literal: true

# Class that finds a TaxonomicName matching a URI
# The instance object must respond to these methods:
# - uri
class TaxonomicName::Find
  def initialize(args)
    uri = args['id']
    @taxonomic_name = Name.find_by(uri: uri.sub(/https:\/\/id.biodiversity.org.au\//,''))
    raise 'no matching taxonomic name' if @taxonomic_name.nil?
  end

  def generic_name
    return nil if @taxonomic_name.name_rank.above_species?

    @taxonomic_name.parent.name_element
  end

  def infrageneric_epithet
    'not implemented'
  end

  # but what about varieties, sub-species?
  def specific_epithet
    retun nil unless @taxonomic_name.species_or_below?
    @taxonomic_name.name_element
  end

  def cultivar_epithet
    'not implemented'
  end

  def infraspecific_epithet
    'not implemented'
  end

  def authorship
    'not stored as a separate component'
  end

  def primary_reference
    'waiting for Reference object to be defined'
  end

  def name_rank_record
    'waiting to be defined'
  end

  def name_status_record
    'waiting to be defined'
  end

  def method_missing(name, *args, &block)
    @taxonomic_name.send(name)
  end
  private

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("TaxonomicName::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end

