# frozen_string_literal: true

# Class that finds a Name Status record matching a URI (id).
# The instance object must respond to attribute methods
# on the Name Status record.
class NameStatus::Find
  def initialize(args)
    id = args['id']
    @name_status = NameStatus.find_by(id: id)
    raise 'no matching name status' if @name_status.nil?
  end

  private

  def method_missing(name, *args, &block)
    @name_status.send(name, *args, &block)
  end

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("NameStatus::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
