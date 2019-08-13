# frozen_string_literal: true

# Class that finds a Taxonomic Name Usage (aka standalone instance) matching
# an ID.
# The instance object must respond to attribute methods as if on the
# retrieved record/object.
class TaxonomicNameUsage::Find
  def initialize(args)
    id = args['id']
    @tn_usage = Instance.find_by(id: id)
    raise 'no matching taxonomic name usage' if @tn_usage.nil?
  end

  private

  def method_missing(name, *args, &block)
    @tn_usage.send(name, *args, &block)
  end

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("TaxonomicNameUsage::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
