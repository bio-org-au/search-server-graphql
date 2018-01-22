# frozen_string_literal: true

# GQL will call the "names" methods on NameSearchResults objects.
# Return the object itself, which is an array.
class NameRank::Search::Results < Array
  def name_ranks
    self
  end
end
