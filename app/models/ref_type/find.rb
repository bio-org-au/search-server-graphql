# frozen_string_literal: true

# Class that finds a Ref Type matching a URI
# The instance object must respond to attribute methods
# for the retrieved record.
class RefType::Find
  def initialize(args)
    id = args['id']
    @ref_type = RefType.find_by(id: id)
    raise 'no matching ref type' if @ref_type.nil?
  end

  def method_missing(name, *args, &block)
    @ref_type.send(name, *args, &block)
  end

  private

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("RefType::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
