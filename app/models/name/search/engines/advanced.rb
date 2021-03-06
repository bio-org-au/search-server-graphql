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

  def names
    val = base_query.left_outer_joins(:family)
                    .includes(:name_status)
                    .includes(:family)
    val = val.select('name.id, name.simple_name, name.full_name, name.family_id')
             .select('name.name_status_id, families_name.full_name family_full_name')
             .select('name.full_name_html')
             .limit(@parser.limit)
             .offset(@parser.offset)
             .order(order_str)
    val
  end

  def total
    base_query.count
  end

  private

  def base_query
    query = Name.has_an_instance
                .left_outer_joins(:name_rank)
                .joins(:name_type)
    query = filter_on_name_and_name_element(query)
    query = filter_on_authors(query)
    query = filter_on_publication(query)
    query = filter_on_genus_species_rank(query)
    query = filter_on_family(query)
    query = Filters::InstanceTypeNote.new(query, @parser).sql
    query.where(Name::Search::NameTypeClause.new(@parser).clause)
  end

  def filter_on_name_and_name_element(query)
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
    Filters::IsoPublicationDate.new(query, @parser).sql
  end

  def filter_on_genus_species_rank(query)
    query = Filters::Genus.new(query, @parser).sql
    query = Filters::Species.new(query, @parser).sql
    query = Filters::Rank.new(query, @parser).sql
    query
  end

  def filter_on_family(query)
    query = Filters::Family.new(query, @parser).sql
  end

  def order_str
    if @parser.family_order?
      'families_name.full_name, name_rank.sort_order, name.sort_name'
    else
      'name.sort_name, name_rank.sort_order'
    end
  end

  private

  def debug(msg)
    Rails.logger.debug("Name::Search::Engines::Advanced: #{msg}")
  end
end
