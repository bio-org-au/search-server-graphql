# frozen_string_literal: true

# Class that find a Name Category matching a URI (id)
# The instance object must respond to attribute methods
# on the name category record
class NameCategory::Find
  def initialize(args)
    id = args['id']
    @name_category = NameCategory.find_by(id: id)
    raise 'no matching name category' if @name_category.nil?
  end

  private

  def method_missing(name, *args, &block)
    @name_category.send(name, *args, &block)
  end

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("NameCategory::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
