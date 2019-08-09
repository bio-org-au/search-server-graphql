# frozen_string_literal: true

# Class that finds TaxonomicNameUsages
# The instance object must respond to these methods:
# - data
# - paginator_info
class TaxonomicNameUsages::Find
  def initialize(args)
    @filter = args['filter']
    debug("@filter['name']: #{@filter['name']}")
    @count = args['count'] || 1
    page = args['page'] || 1
    size = args['size'] || 10
    offset = (page - 1) * size
    limit = size
    @usages = search
  end

  def data
    debug("@usages.size: #{@usages.size}")
    @usages
  end

  def paginator_info
    ostruct = OpenStruct.new
    ostruct.count = @count
    ostruct.page = nil
    ostruct
  end

  private

  def search
    debug('search')
    @usages = Instance.where(["name_id in (select id from name where lower(full_name) like lower(?))", (@filter['name'].strip)+'%']).limit(10)
  end

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("TaxonomicNameUsages::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
