# frozen_string_literal: true

# Class that conducts name_rank searches
# The instance object must respond to these methods:
# - options 
class NameRank::Search::Base
  def options
    NameRank.new.options
  end
end
