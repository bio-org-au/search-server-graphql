# frozen_string_literal: true

# Search Engines for simple name searches
# The object must respond to these methods:
# - names
# - count
class Name::Search::Engines::Simple
  def initialize(args)
    debug('initialize')
    @args = args
    @parser = Name::Search::Parser.new(args)
  end

  def debug(s)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("Name::Search::Engines::Simple: #{s}")
    Rails.logger.debug('==============================================')
  end

  def names
    base_query.joins(:family)
              .includes(:name_status)
              .includes(:family)
              .joins(:name_rank)
              .select('name.simple_name, name.full_name, name.family_id, name.name_status_id, families_name.full_name')
              .limit(@parser.limit)
              .offset(@parser.offset)
              .ordered_by_sort_name_and_rank
  end

  def count
    base_query.size
  end

  private

  def base_query
    Name.name_matches(@parser.search_term)
        .has_an_instance
  end
end
