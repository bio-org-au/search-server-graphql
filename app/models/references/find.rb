# frozen_string_literal: true

# Class that finds References
# The instance object must respond to these methods:
# - paginator_info
# - data
class References::Find

  def initialize(args)
    @per_page = args['count'] || 10
    @page = args['page'] || 1
    @offset = (@page - 1) * @per_page
    @limit = @per_page
    @total = Reference.all.count
    @references = Reference.all
                           .includes(:ref_type)
                           .includes(:ref_author_role)
                           .includes(:author)
                           .order(:citation)
                           .offset(@offset)
                           .limit(@per_page)
  end

  def data
    @references
  end

  def paginator_info
    PaginatorInfo.new(@per_page, @page, @total, @offset).build
  end

  private

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("References::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
