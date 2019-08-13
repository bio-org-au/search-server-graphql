# frozen_string_literal: true

# Class that finds a Reference record matching a URI (id).
# The instance object must respond to attribute methdods 
# on the retrieved object/record.
class Reference::Find
  def initialize(args)
    id = args['id']
    @reference = Reference.find_by(id: id)
    raise 'no matching reference' if @reference.nil?
  end

  def method_missing(name, *args, &block)
    @reference.send(name)
  end

  private

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("Reference::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
