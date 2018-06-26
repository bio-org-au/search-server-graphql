# frozen_string_literal: true

# Search Engines for advanced name searches
# The object must respond to these methods:
# - names
# - count
class Name::Search::Engines::Advanced
  def initialize(args)
    debug('initialize')
    @args = args
    @parser = Name::Search::Parser.new(args)
  end

  def debug(s)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("Name::Search::Engines::Advanced: #{s}")
    Rails.logger.debug('==============================================')
  end

  def names
    debug("@parser.limit: #{@parser.limit}")
    val = base_query.joins(:family)
                    .includes(:name_status)
                    .includes(:family)
    val = val.select('name.simple_name, name.full_name, name.family_id')
             .select('name.name_status_id, families_name.full_name')
             .limit(@parser.limit)
             .offset(@parser.offset)
             .ordered_by_sort_name_and_rank
    val
  end

  def count
    base_query.size
  end

  private

  def base_query
    query = Name.has_an_instance
                .joins(:name_rank)
                .joins(:name_type)
    query = filter_on_name_and_name_element(query)
    query = filter_on_authors(query)
    query = filter_on_publication(query)
    query = filter_on_genus_species_rank(query)
    query = Filters::InstanceTypeNote.new(query, @parser).sql
    query.where(Name::Search::NameTypeClause.new(@parser).clause)
  end

  def filter_on_name_and_name_element(query)
    query = Filters::NameElement.new(query, @parser).sql
    Filters::SearchTerm.new(query, @parser).sql
  end

  def filter_on_authors(query)
    query = Filters::Author.new(query, @parser).sql
    query = Filters::ExAuthor.new(query, @parser).sql
    query = Filters::BaseAuthor.new(query, @parser).sql
    Filters::ExBaseAuthor.new(query, @parser).sql
  end

  def filter_on_publication(query)
    query = Filters::Publication.new(query, @parser).sql
    Filters::PublicationYear.new(query, @parser).sql
  end

  def filter_on_genus_species_rank(query)
    query = Filters::Genus.new(query, @parser).sql
    query = Filters::Species.new(query, @parser).sql
    query = Filters::Rank.new(query, @parser).sql
    query
  end
end
