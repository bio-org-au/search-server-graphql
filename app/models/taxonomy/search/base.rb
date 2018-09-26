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

  def debug(s)
    Rails.logger.debug("===================================================")
    Rails.logger.debug("Taxonomy::Search::Base: #{s}")
    Rails.logger.debug("===================================================")
  end

  # The returned object must respond to the "taxa" message
  # I create a structure here so I can send the value of the booleans
  # correctly.
  # I use the select clause column names to avoid long, involved additional
  # queries e.g. from name to tree_element (but which tree element - there 
  # can be many, and the search query knows which one)
  #
  # Recently this was emitting an error in testing:
  # unknown OID 705: failed to recognize type of 'cross_referenced_full_name'. It will be treated as String.
  # The if statement for coun > 0 stops this test error.
  def taxa
    taxonomy_search_results = Taxonomy::Search::Results.new
    gs = @generator.search
    if @generator.count > 0
      gs.each do |name_tree_element|
        if name_tree_element.try('cross_reference') == true ||
             name_tree_element.try('cross_reference') == 't'
          taxonomy_search_results.push(cross_reference_struct(name_tree_element))
        else
          taxonomy_search_results.push(direct_reference_struct(name_tree_element))
        end
      end
    end
    taxonomy_search_results
  end

  def direct_reference_struct(name_tree_element)
    struct = OpenStruct.new

    if name_tree_element.profile.class == String
      profile = JSON.parse(name_tree_element.profile)
    else
      profile = name_tree_element.profile
    end

    if profile.nil?
      struct[:taxon_distribution] = ''
      struct[:taxon_comment] = ''
    else
      unless profile["APC Dist."].blank?
        struct[:taxon_distribution] = profile["APC Dist."]["value"]
      end
      unless profile["APC Comment"].blank?
        struct[:taxon_comment] = profile["APC Comment"]["value"]
      end
    end

    struct[:full_name] = name_tree_element.full_name
    struct[:full_name_html] = name_tree_element.full_name_html
    struct[:id] = name_tree_element[:id]
    struct[:instance_id] = name_tree_element.instance_id
    struct[:is_excluded] = name_tree_element.excluded == true ||
                           name_tree_element.excluded == 't'
    struct[:is_cross_reference] = name_tree_element.try('cross_reference') == true ||
                                  name_tree_element.try('cross_reference') == 't'
    struct[:is_misapplication] = name_tree_element.misapplied == true ||
                                 name_tree_element.misapplied == 't'
    struct[:is_pro_parte] = name_tree_element.pro_parte == true ||
                            name_tree_element.pro_parte == 't'
    #struct[:name_status_id] = name_tree_element.name_status_id
    struct[:name_status_name] = name_tree_element.name_status_name_
    # The name_status.display boolean is not set up.
    struct[:name_status_is_displayed] = !(name_tree_element.name_status.name == 'legitimate' || name_tree_element.name_status.name.match(/^\[/))
    struct[:order_string] = name_tree_element.name_path
    #struct[:reference_id] = name_tree_element.reference_id
    struct[:reference_citation] = name_tree_element.reference_citation
    struct[:simple_name] = name_tree_element.simple_name
    #struct[:source_object] = nil
    
    syn_array = []
    synonyms = if name_tree_element.synonyms.class == String
                 JSON.parse(name_tree_element.synonyms)
               else
                 name_tree_element.synonyms
               end
    unless synonyms.nil? || synonyms["list"].nil?
    synonyms["list"].sort {|x,y| x["simple_name"] <=> y["simple_name"] }.each do | syn |
      syn_struct = OpenStruct.new
      syn_struct[:id] = syn["instance_id"]
      syn_struct[:name_id] = syn["name_id"]
      syn_struct[:simple_name] = syn["simple_name"]
      name = Name.where(id: syn["name_id"]).includes(:name_status).first
      instance = Instance.where(id: syn["instance_id"]).includes(:instance_type).first
      syn_struct[:full_name] = name.full_name
      syn_struct[:full_name_html] = name.full_name_html
      syn_struct[:name_status] = name.name_status.name
      # The name_status.display boolean is not set up.
      syn_struct[:name_status_is_displayed] = !(name.name_status.name == 'legitimate' || name.name_status.name.match(/^\[/))
      syn_struct[:is_doubtful] = instance.instance_type.doubtful
      syn_struct[:is_misapplied] = instance.instance_type.misapplied
      syn_struct[:is_pro_parte] = instance.instance_type.pro_parte

      syn_array.push(syn_struct)
    end
    end

    #name_tree_element.synonyms.class
    # struct[:synonyms] = name_tree_element.synonyms["list"].collect {|h| {'name_id': h["name_id"], 'simple_name': h["simple_name"], 'full_name_html': Name.find(h["name_id"]).full_name} }; ''
    struct[:synonyms] = syn_array
    struct
  end

  def cross_reference_struct(name_tree_element)
    struct = OpenStruct.new
    #struct[:cites_instance_id] = name_tree_element.cites_id
    struct[:cross_reference_full_name] = 'deprecated'
    #struct[:cross_reference_misapplication_details] = nil

    cross_ref_to_struct = OpenStruct.new
    cross_ref_to_struct[:name_id] = name_tree_element.cross_referenced_full_name_id
    cross_ref_to_struct[:full_name] = name_tree_element.cross_referenced_full_name
    cross_ref_to_struct[:full_name_html] = name_tree_element.cross_ref_full_name_html
    cross_ref_to_struct[:is_pro_parte] = name_tree_element.pro_parte == 't'
    cross_ref_to_struct[:is_doubtful] = name_tree_element.doubtful == 't'

    cross_ref_to_struct[:is_misapplication] = name_tree_element.misapplied == 't' 
    if name_tree_element.misapplied == 't'
      as_misapplication_struct = OpenStruct.new
      as_misapplication_struct[:citing_instance_id] = -2
      as_misapplication_struct[:citing_reference_id] = -1
      as_misapplication_struct[:citing_reference_author_string_and_year] = -1
      as_misapplication_struct[:misapplying_author_string_and_year] = name_tree_element.reference_citation.sub(/\),.*/,')')
      as_misapplication_struct[:name_author_string] = -1
      as_misapplication_struct[:cited_simple_name] = -1
      as_misapplication_struct[:cited_page] = -1
      as_misapplication_struct[:cited_reference_author_string] = name_tree_element.reference_citation.sub(/\),.*/,')')
      cross_ref_to_struct[:as_misapplication] = as_misapplication_struct
    end
    struct[:cross_reference_to] = cross_ref_to_struct

    struct[:full_name] = name_tree_element.full_name
    struct[:full_name_html] = name_tree_element.full_name_html
    struct[:id] = name_tree_element[:id]
    struct[:instance_id] = name_tree_element.instance_id
    struct[:is_excluded] = name_tree_element.excluded == true ||
                           name_tree_element.excluded == 't'
    struct[:is_cross_reference] = name_tree_element.cross_reference == true ||
                                  name_tree_element.cross_reference == 't'
    struct[:is_misapplication] = name_tree_element.misapplied == true ||
                                 name_tree_element.misapplied == 't'
    struct[:is_pro_parte] =  name_tree_element.pro_parte == 't'
    struct[:name_status_name] = name_tree_element.name_status_name_
    struct[:name_status_is_displayed] = !(name_tree_element.name_status.name == 'legitimate' || name_tree_element.name_status.name.match(/^\[/))
    struct[:order_string] = name_tree_element.name_path
    struct[:simple_name] = name_tree_element.simple_name
    struct
  end
end
