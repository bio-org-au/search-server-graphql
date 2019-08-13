# frozen_string_literal: true

# Class that find a TaxonomicNameUsageNote matching an ID
# The instance note object must respond to attribute methods
# as if called on the retrieved object/record.
class TaxonomicNameUsageNote::Find
  def initialize(args)
    id = args['id']
    @instance_note = InstanceNote.find_by(id: id)
    raise 'no matching TaxonomicNameUsageNote' if @instance_note.nil?
  end

  private

  def method_missing(name, *args, &block)
    @instance_note.send(name, *args, &block)
  end

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("TaxonomicNameUsageNote::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
