# frozen_string_literal: true

# Class that finds a Name Type matching a URI (id)
# The instance object must respond to attribute methods of
# the retrieved record.
class NameType::Find
  def initialize(args)
    id = args['id']
    @name_type = NameType.find_by(id: id)
    raise 'no matching name type' if @name_type.nil?
  end

  private

  def method_missing(name, *args, &block)
    @name_type.send(name, *args, &block)
  end

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("NameType::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
