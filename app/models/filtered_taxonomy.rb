# frozen_string_literal: true

class FilteredTaxonomy
  def initialize(args)
    @args = args
    @filter = args['filter']
    @per_page = args['count'] || 10
    @page = args['page'] || 1
    @offset = (@page - 1) * @per_page
    @limit = @per_page
    @base_search = Taxonomy::Search::Base.new(args)
    @total = @base_search.total
    @taxa = @base_search.taxa
  end

  def answer
    ostruct = OpenStruct.new
    ostruct.paginator_info = paginator_info
    ostruct.data = @taxa
    ostruct
  end

  def args_and_values
    array = []
    @filter.each do |key, value|
      array.push("#{key}: #{value}")
    end
    array
  end

  def paginator_info
    PaginatorInfo.new(@per_page, @page, @total, @offset).build
  end
end
