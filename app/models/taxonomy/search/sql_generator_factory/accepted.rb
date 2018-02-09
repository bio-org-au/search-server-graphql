# frozen_string_literal: true

# Produce sql for taxonomy queries.
class Taxonomy::Search::SqlGeneratorFactory::Accepted
  def initialize(parser)
    @parser = parser
  end

  def search
    AcceptedName.accepted
                .ordered
                .name_matches(@parser.search_term)
                .includes(:status)
                .includes(:reference)
                .limit(@parser.limit)
                .offset(@parser.offset)
  end

  def count
    AcceptedName.accepted.name_matches(@parser.search_term).count
  end
end
