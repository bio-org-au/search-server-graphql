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
    Rails.logger.debug("Name::Search::Merge: #{s}")
  end

  def explore
    debug('===========================================================')
    debug('merge')
    debug('===========================================================')
    @names_array.each do |record|
      debug("class: #{record.class}")
      debug("id: #{record.id}")
      debug("full name: #{record.full_name}")
      debug("name usages: #{record.name_usages.class}")
      debug("name usages size: #{record.name_usages.size}")
      record.name_usages.each do |usage|
        if usage.misapplied
          debug("misapplied: ref id: #{usage.reference_id}; name id: #{usage.misapplied_to_id}: #{usage.misapplied_to_name}")
          debug("misapplied: #{usage.citation} #{usage.page} (#{usage.instance_id})")
        else
          debug("not misapplied: #{usage.citation} #{usage.page} (#{usage.instance_id})")
        end
      end
    end
    debug('===========================================================')
    debug('===========================================================')
  end

  def merge
    explore
    @names_array
  end
end
