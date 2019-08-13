# frozen_string_literal: true

# Class that finds TaxonomicNameUsages
# The instance object must respond to these methods:
# - data
# - paginator_info
class TaxonomicNameUsages::Find
  STANDALONE = 'cited_by_id is null'
  SUB_QUERY = ' (select id from name where lower(full_name) like lower(?))'
  def initialize(args)
    @filter = args['filter']
    debug("@filter['name']: #{@filter['name']}")
    @per_page = args['count'] || 10
    @page = args['page'] || 1
    @offset = (@page - 1) * @per_page
    @limit = @per_page
    @total = count_total
    @usages = search
  end

  def data
    debug("@usages.size: #{@usages.size}")
    @usages
  end

  def paginator_info
    PaginatorInfo.new(@per_page, @page, @total, @offset).build
  end

  private

  def count_total
    if @filter.nil?
      Instance.where([STANDALONE]).count
    else
      Instance.where(["#{STANDALONE} and name_id in #{SUB_QUERY}",
                      @filter['name'].strip + '%'])
              .count
    end
  end

  def search
    if @filter.nil?
      Instance.where([STANDALONE]).offset(@offset).limit(@limit)
    else
      Instance.where(["#{STANDALONE} and name_id in #{SUB_QUERY}",
                      @filter['name'].strip + '%'])
              .offset(@offset)
              .limit(@limit)
    end
  end

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("TaxonomicNameUsages::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
