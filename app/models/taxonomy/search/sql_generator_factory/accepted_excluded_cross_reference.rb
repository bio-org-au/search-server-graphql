# frozen_string_literal: true

# Produce sql for taxonomy queries.
class Taxonomy::Search::SqlGeneratorFactory::AcceptedExcludedCrossReference
  def initialize(parser)
    @parser = parser
  end

  def search
    NameOrSynonym.name_matches(@parser.search_term)
                .limit(@parser.limit)
                .offset(@parser.offset)
                #.includes(:status)
                #.ordered
  end

  def count
    NameOrSynonym.name_matches(@parser.search_term).count
  end
end


 
