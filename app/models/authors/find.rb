# frozen_string_literal: true

# Class that find an Author matching a URI
# The instance object must respond to these methods:
# - id (uri)
# - fullName: String
# - standardForm: String
# - ipniId: String
# - name: String
class Authors::Find
  def initialize(args)
    page = args['page'] || 1
    size = args['size'] || 10
    offset = (page - 1) * size
    limit = size
    @authors = Author.all.order(:name).offset(offset).limit(limit)
  end

  def authors
    @authors
  end

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("Authors::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
