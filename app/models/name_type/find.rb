# frozen_string_literal: true

# Class that find an Author matching a URI
# The instance object must respond to these methods:
# - id (uri)
# - fullName: String
# - standardForm: String
# - ipniId: String
# - name: String
class NameType::Find
  def initialize(args)
    id = args['id']
    @name_type = NameType.find_by(id: id)
    raise 'no matching name type' if @name_type.nil?
  end

  private

  def method_missing(name, *args, &block)
    @name_type.send(name)
  end

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("NameType::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
