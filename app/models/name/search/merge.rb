# frozen_string_literal: true

# Class that conducts name searches
# The instance object must respond to these methods:
# - names
# - count
class Name::Search::Merge
  def initialize(names_array)
    @names_array = names_array
  end

  def debug(s)
    # Rails.logger.debug("======= Name::Search::Merge: #{s}")
  end

  def explore
    debug('===========================================================')
    debug('start merge')
    debug('===========================================================')
    @names_array.each do |record|
      debug("class: #{record.class}")
      debug("id: #{record.id}")
      debug("full name: #{record.full_name}")
      debug("name usages: #{record.name_usages.class}")
      debug("name usages size: #{record.name_usages.size}")
      current_name_id = record.id
      current_reference_id = 0
      current_page = -1
      current_type = "not a type"
      record.name_usages.each do |usage|
        if usage.misapplication
          debug("                                                       x")
          debug("==============  ============ =============== ==========")
          debug("name_usage loop")
          debug("usage.class: #{usage.class}")
          debug("name id: #{record.id}; name: #{record.full_name};")
          debug("                                                       x")
          debug("#{usage.reference_details.citation}")
          debug("#{usage.instance_type_name}")
          debug("page: #{usage.reference_details.page}")
          debug("Misapplication!") if usage.misapplication

          if current_name_id == record.id
            debug("Same name!")
            same_name = true
          else
            debug("New name.")
            same_name = false
          end
          current_name_id = record.id

          if current_reference_id == usage.reference_details.id
            debug("Same reference!")
            same_ref = true
          else
            debug("Diferent reference!")
            same_ref = false
          end
          current_reference_id = usage.reference_details.id

          if current_page == usage.reference_details.page
            debug("Same page!")
            same_page = true
          else
            debug("New page.")
            same_page = false
          end
          current_page = usage.reference_details.page

          if current_type == usage.instance_type_name
            debug("Same type!")
            same_type = true
          else
            debug("New type.")
            same_type = false
          end
          current_type = usage.instance_type_name

          merge = same_name && same_ref && same_page && same_type

          debug("Merge!!!!!!") if merge

          debug("                                                       x")
        end
      end
    end
    debug('===========================================================')
    debug('end merge')
    debug('===========================================================')
  end

  def merge
    explore
    @names_array
  end
end
