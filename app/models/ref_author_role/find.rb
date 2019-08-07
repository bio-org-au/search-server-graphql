# frozen_string_literal: true

# Class that find an Author matching a URI
# The instance object must respond to these methods:
# - id (uri)
# - name: String
class RefAuthorRole::Find
  def initialize(args)
    id = args['id']
    @ref_author_role = RefAuthorRole.find_by(id: id)
    raise 'no matching ref author role' if @ref_author_role.nil?
  end

  def method_missing(name, *args, &block)
    @ref_author_role.send(name)
  end

  private

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("RefAuthorRole::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
