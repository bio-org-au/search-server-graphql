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
                .order("sort_name,
                        case cites_misapplied when true then 'Z' else 'A' end,
                        cites_cites_ref_year")
                 .select(' id, simple_name, full_name, full_name_html, type_code, instance_id, tree_node_id, accepted_id, accepted_full_name, name_status_id, reference_id, name_rank_id, sort_name, synonym_type_id, synonym_ref_id, citer_instance_id, cites_instance_id, cites_instance_type_name, cites_misapplied, citer_ref_year, cites_cites_id, cites_cites_ref_id, cites_cites_ref_year')
                #.includes(:status)
                #.ordered
  end

  def count
    NameOrSynonym.name_matches(@parser.search_term).count
  end
end


 
