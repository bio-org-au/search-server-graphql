# frozen_string_literal: true

# Class that finds References
# The instance object must respond to these methods:
# - paginator_info
# - data
class References::Find
  def initialize(args)
    @count = args['count'] || 1
    page = args['page'] || 1
    size = args['size'] || 10
    offset = (page - 1) * size
    limit = size
    #@references = Reference.all.order(:citation).offset(offset).limit(limit)
    @references = Reference.all.order(:citation).limit(@count)
  end

  def data
    @references
  end

  def paginator_info
    ostruct = OpenStruct.new
    ostruct.count = @count
    ostruct.page = nil
    ostruct
  end

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("References::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
