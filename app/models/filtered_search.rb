class FilteredSearch
  def initialize(args)
    @args = args
    @filter = args["filter"]
  end

  def answer
    ostruct = OpenStruct.new
    ostruct.paginator_info = paginator_info
    ostruct.data = args_and_values
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
    @per_page = 10
    @page = 1
    @total = 0
    @offset = 0
    PaginatorInfo.new(@per_page, @page, @total, @offset).build
  end

  def cxlsdldsf
    "answer. args: #{@args.inspect}"
    @args.keys.join(',')
    Hash.new.methods.sort.join
    Hash.new.methods.sort.join
    @args.inspect
    summary = ""
    @args.keys.each do |key|
      summary += "#{key}: #{@args[key]}; "
    end
    summary
  end
end
