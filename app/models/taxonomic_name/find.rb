# frozen_string_literal: true

# Class that finds a TaxonomicName matching a URI
# The instance object must respond to attribute methods
# on the retrieved record.
class TaxonomicName::Find
  def initialize(args)
    uri = args['id']
    @taxonomic_name = Name.find_by(uri: uri.sub(/https:\/\/id.biodiversity.org.au\//,''))
    raise 'no matching taxonomic name' if @taxonomic_name.nil?
  end

  private

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

