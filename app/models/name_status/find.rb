# frozen_string_literal: true

# Class that find an Author matching a URI
# The instance object must respond to these methods:
# - id (uri)
# - fullName: String
# - standardForm: String
# - ipniId: String
# - name: String
class NameStatus::Find
  def initialize(args)
    id = args['id']
    @name_status = NameStatus.find_by(id: id)
    raise 'no matching name status' if @name_status.nil?
  end

  def xdisplay
    true
  end

  def method_missing(name, *args, &block)
    @name_status.send(name)
  end

  private

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("NameStatus::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
