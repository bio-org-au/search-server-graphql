class PaginatorInfo

  def initialize(per_page, page, total, offset)
    @per_page = per_page
    @page = page
    @total = total
    @offset = offset
  end

  def build
    ostruct = OpenStruct.new
    ostruct.count = @per_page
    ostruct.currentPage = @page
    ostruct.perPage = @per_page
    last_page = (@total/@per_page) + 1
    if @offset > @total
      ostruct.firstItem = nil
      ostruct.lastItem = nil
    else
      ostruct.firstItem = (@per_page * (@page - 1)) + 1
      if @page < last_page
        ostruct.lastItem = (@per_page * @page)
      else
        ostruct.lastItem = @total
      end
    end
    ostruct.lastPage = (@total/@per_page) + 1
    ostruct.hasMorePages = @total > (@per_page * @page)
    ostruct.total = @total
    ostruct
  end

end
