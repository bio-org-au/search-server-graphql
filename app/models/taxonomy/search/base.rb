# frozen_string_literal: true

# Class that conducts taxonomy searches
class Taxonomy::Search::Base
  def initialize(args)
    @args = args
    @parser = Taxonomy::Search::Parser.new(@args)
    @generator = Taxonomy::Search::SqlGeneratorFactory.new(@parser).build
  end

  # The returned object must respond to the "count" message
  def count
    @generator.count
  end

  # The returned object must respond to the "taxa" message
  # I create a structure here so I can send the value of the booleans
  # correctly.
  # I use the select clause column names to avoid long, involved additional
  # queries e.g. from name to tree_element (but which tree element - there 
  # can be many, and the search query knows which one)
  def taxa
    taxonomy_search_results = Taxonomy::Search::Results.new
    @generator.search.each do |name_tree_element|
      if name_tree_element.try('cross_reference') == 't'
        taxonomy_search_results.push(cross_reference_struct(name_tree_element))
      else
        taxonomy_search_results.push(direct_reference_struct(name_tree_element))
      end
    end
    taxonomy_search_results
  end

  def direct_reference_struct(name_tree_element)
    struct = OpenStruct.new
    #struct[:accepted_taxon_comment] = 'xxx'
    #struct[:accepted_taxon_distribution] = name_tree_element.profile
    #struct[:cites_instance_id] = name_tree_element.cites_id
    struct[:full_name] = name_tree_element.full_name
    struct[:full_name_html] = name_tree_element.full_name_html
    struct[:id] = name_tree_element[:id]
    struct[:instance_id] = name_tree_element.instance_id
    struct[:is_excluded] = name_tree_element.excluded == 't'
    struct[:is_cross_reference] = name_tree_element.try('cross_reference') == 't'
    struct[:is_misapplication] = name_tree_element.misapplied == 't'
    struct[:is_pro_parte] =  name_tree_element.pro_parte == 't'
    #struct[:name_status_id] = name_tree_element.name_status_id
    struct[:name_status_name] = name_tree_element.name_status_name_
    struct[:order_string] = name_tree_element.name_path
    #struct[:reference_id] = name_tree_element.reference_id
    #struct[:reference_citation] = name_tree_element.reference_citation
    struct[:simple_name] = name_tree_element.simple_name
    #struct[:source_object] = nil
    #struct[:synonyms] = nil
    struct
  end

  def cross_reference_struct(name_tree_element)
    struct = OpenStruct.new
    #struct[:accepted_taxon_comment] = 'xxx'
    #struct[:accepted_taxon_distribution] = name_tree_element.profile
    #struct[:cites_instance_id] = name_tree_element.cites_id
    struct[:cross_reference_full_name] = 'deprecated'
    #struct[:cross_reference_misapplication_details] = nil

    cross_ref_to_struct = OpenStruct.new
    cross_ref_to_struct[:full_name] = name_tree_element.cross_ref_full_name
    cross_ref_to_struct[:full_name_html] = name_tree_element.cross_ref_full_name_html
    cross_ref_to_struct[:is_pro_parte] = name_tree_element.pro_parte == 't'
    cross_ref_to_struct[:is_doubtful] = name_tree_element.doubtful == 't'

    cross_ref_to_struct[:is_misapplication] = name_tree_element.misapplied == 't' 
    if name_tree_element.misapplied == 't'
      as_misapplication_struct = OpenStruct.new
      as_misapplication_struct[:citing_instance_id] = -2
      as_misapplication_struct[:citing_reference_id] = -1
      as_misapplication_struct[:citing_reference_author_string_and_year] = -1
      as_misapplication_struct[:misapplying_author_string_and_year] = name_tree_element.cited_ref_citation.sub(/\),.*/,')')
      as_misapplication_struct[:name_author_string] = -1
      as_misapplication_struct[:cited_simple_name] = -1
      as_misapplication_struct[:cited_page] = -1
      as_misapplication_struct[:cited_reference_author_string] = name_tree_element.cited_ref_citation.sub(/\),.*/,')')
      cross_ref_to_struct[:as_misapplication] = as_misapplication_struct
    end
    struct[:cross_reference_to] = cross_ref_to_struct

    struct[:full_name] = name_tree_element.full_name
    struct[:full_name_html] = name_tree_element.full_name_html
    struct[:id] = name_tree_element[:id]
    struct[:instance_id] = name_tree_element.instance_id
    struct[:is_excluded] = name_tree_element.excluded == 't'
    struct[:is_cross_reference] = name_tree_element.cross_reference == 't'
    struct[:is_misapplication] = name_tree_element.misapplied == 't'
    struct[:is_pro_parte] =  name_tree_element.pro_parte == 't'
    #struct[:name_status_id] = name_tree_element.name_status_id
    struct[:name_status_name] = name_tree_element.name_status_name_
    struct[:order_string] = name_tree_element.name_path
    #struct[:reference_id] = name_tree_element.reference_id
    #struct[:reference_citation] = name_tree_element.reference_citation
    struct[:simple_name] = name_tree_element.simple_name
    #struct[:source_object] = nil
    #struct[:synonyms] = nil
    struct
  end
end
