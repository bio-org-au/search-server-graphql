# frozen_string_literal: true

# Class that find a Name Group matching a URI (id)
# The instance object must respond to attribute methods of
# the name group record.
class NameGroup::Find
  def initialize(args)
    id = args['id']
    @name_group = NameGroup.find_by(id: id)
    raise 'no matching name group' if @name_group.nil?
  end

  private

  def method_missing(name, *args, &block)
    @name_group.send(name, *args, &block)
  end

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("NameGroup::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
