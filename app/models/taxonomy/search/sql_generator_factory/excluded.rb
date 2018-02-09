# frozen_string_literal: true

# Produce sql for taxonomy queries.
class Taxonomy::Search::SqlGeneratorFactory::Excluded
  def initialize(parser)
    @parser = parser
  end

  def search
    AcceptedName.excluded
                .ordered
                .name_matches(@parser.search_term)
                .includes(:status)
                .limit(@parser.limit)
                .offset(@parser.offset)
  end


  def count
    AcceptedName.excluded.name_matches(@parser.search_term).count
  end
end


