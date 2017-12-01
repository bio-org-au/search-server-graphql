# frozen_string_literal: true

# GQL will call the "names" methods on NameSearchResults objects.
# Return the object itself, which is an array.
class Reference::Search::Results < Array
  def references
    self
  end
end
