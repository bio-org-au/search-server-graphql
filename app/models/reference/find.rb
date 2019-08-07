# frozen_string_literal: true

# Class that find an Author matching a URI
# The instance object must respond to these methods:
# - id (uri)
# - fullName: String
# - standardForm: String
# - ipniId: String
# - name: String
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
