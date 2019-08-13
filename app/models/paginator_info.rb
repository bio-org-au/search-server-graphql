# frozen_string_literal: true

# Generate standard pageinator info.
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
    build_last_page
    build_first_and_last_item
    ostruct.firstItem = @first_item
    ostruct.lastItem = @last_item
    ostruct.lastPage = @last_page
    ostruct.hasMorePages = @total > (@per_page * @page)
    ostruct.total = @total
    ostruct
  end

  def build_first_and_last_item
    if @offset >= @total
      @first_item = @last_item = nil
    else
      @first_item = (@per_page * (@page - 1)) + 1
      @last_item = if @page < @last_page
                     (@per_page * @page)
                   else
                     @total
                   end
    end
  end

  def build_last_page
    last_page_real = ((@total * 1.0) / @per_page)
    last_page_int = (@total / @per_page)
    @last_page = if last_page_real > last_page_int
                   last_page_int + 1
                 else
                   last_page_int
                 end
  end
end
