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
    Rails.logger.debug("Name::Search::Merger: #{s}")
  end

  def explore
    debug('merge')
    @names_array.each do |record|
      debug("id: #{record.id}")
      debug("full name: #{record.full_name}")
      debug("name history: #{record.name_history.class}")
      debug("name usages: #{record.name_history.name_usages.class}")
      debug("name usages size: #{record.name_history.name_usages.size}")
      record.name_history.name_usages.each do |usage|
        debug("#{usage.citation} #{usage.page} (#{usage.instance_id})")
      end
    end
  end

  def merge
    @names_array
  end
end

