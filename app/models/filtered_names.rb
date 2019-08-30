class FilteredNames
  def initialize(args)
    @args = args
    @filter = args["filter"]
    @per_page =  args["count"] || 10
    @page = args['page'] || 1
    @offset = (@page - 1) * @per_page
    @limit = @per_page
    @base_search = Name::Search::Base.new(args)
    @total = @base_search.total
    @names = @base_search.names
  end

  def answer
    ostruct = OpenStruct.new
    ostruct.paginator_info = paginator_info
    ostruct.data = @names
    ostruct
  end

  def args_and_values
    array = Array.new
    @filter.each do | key, value |
      array.push("#{key}: #{value}")
    end
    array
  end

  def paginator_info
    PaginatorInfo.new(@per_page, @page, @total, @offset).build
  end
end

