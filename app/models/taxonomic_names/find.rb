# frozen_string_literal: true

# Class that finds Taxonomic Names
# The instance object must respond to these methods:
# - paginator_info
# - data
class TaxonomicNames::Find
  FNAME_CLAUSE = 'lower(f_unaccent(name.full_name)) like lower(f_unaccent(?))'
  SNAME_CLAUSE = 'lower(f_unaccent(name.full_name)) like lower(f_unaccent(?))'

  def initialize(args)
    @name_s = args['fullName'] || '%'

    @per_page = args['count'] || 1
    @page = args['page'] || 1

    @offset = (@page - 1) * @per_page
    @limit = @per_page
    @total = count_total_full
    @taxonomic_names = search_on_full_name
    return unless @total.zero?

    @total = count_total_simple
    @taxonomic_names = search_on_simple_name
  end

  def data
    @taxonomic_names
  end

  def paginator_info
    PaginatorInfo.new(@per_page, @page, @total, @offset).build
  end

  private

  def search_on_full_name
    Name.where([FNAME_CLAUSE, @name_s])
        .order(:full_name)
        .offset(@offset)
        .limit(@limit)
  end

  def search_on_simple_name
    Name.where([SNAME_CLAUSE, @name_s])
        .order(:full_name)
        .offset(@offset)
        .limit(@limit)
  end

  def count_total_full
    @taxonomic_names = Name.where([FNAME_CLAUSE, @name_s]).count
  end

  def count_total_simple
    @taxonomic_names = Name.where([SNAME_CLAUSE, @name_s]).count
  end

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("TaxonomicNames::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
