# frozen_string_literal: true

# For a given instance ID, retrieve a set of ordered
# synonymy instance results suitable for displaying within a name usage.
class Name::Search::Synonym::Pick
  attr_reader :results, :id
  def initialize(instance_id, synonym_bunch)
    @instance_id = instance_id
    @synonym_bunch = synonym_bunch
    @results = []
    build_results
  end

  def debug(s)
    # Rails.logger.debug("Name::Search::Synonym::Pick: #{s}")
  end

  def build_results
    debug("===========================================")
    debug("build_results")
    debug("===========================================")
    prev_name_id = 0
    prev_ref_id = 0
    prev_type_name = ''
    @synonym_bunch.results.each do |instance|
      if instance.misapplied == 't'
        debug("misapplied")
        debug("instance.name_id: #{instance.name_id}")
        debug("instance.full_name: #{instance.name.full_name}")
        debug("instance.reference_id: #{instance.reference_id}")
        debug("instance.reference_citation: #{instance.reference_citation}")
        debug("instance.instance_type_name: #{instance.instance_type_name}")
        if prev_name_id == instance.name_id &&
            prev_ref_id == instance.reference_id &&
            prev_type_name == instance.instance_type_name
          misapp_name_repeated = true
        else
          misapp_name_repeated = false
        end
        prev_name_id = instance.name_id
        prev_ref_id = instance.reference_id
        prev_type_name = instance.instance_type_name
      end
      if instance[:cited_by_id] == @instance_id
        @results.push(Name::Search::Synonym.new(instance, 'has', misapp_name_repeated))
      end
      if instance[:instance_id] == @instance_id
        if instance.misapplied == 'f'
          @results.push(Name::Search::Synonym.new(instance, 'of'))
        end
      end
    end
    debug("===========================================")
    debug("end build_results")
    debug("===========================================")
  end
end
