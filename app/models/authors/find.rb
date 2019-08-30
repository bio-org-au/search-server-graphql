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
    @per_page = args['count'] || 1
    @page = args['page'] || 1

    @offset = (@page - 1) * @per_page
    @limit = @per_page
    @total = Author.all.count
    @authors = Author.all.order('name, abbrev').offset(@offset).limit(@per_page)
  end

  def data
    @authors
  end

  def paginator_info
    PaginatorInfo.new(@per_page, @page, @total, @offset).build
  end

  private

  def debug(msg)
    Rails.logger.debug("Authors::Find: #{msg}")
  end
end
