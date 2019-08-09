# frozen_string_literal: true

# Class that find an Author matching a URI
# The instance object must respond to these methods:
# - id (uri)
# - fullName: String
# - standardForm: String
# - ipniId: String
# - name: String
class NameGroup::Find
  def initialize(args)
    id = args['id']
    @name_group = NameGroup.find_by(id: id)
    raise 'no matching name group' if @name_group.nil?
  end

  private

  def method_missing(name, *args, &block)
    @name_group.send(name)
  end

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("NameGroup::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
