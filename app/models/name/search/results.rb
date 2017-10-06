# frozen_string_literal: true

# GQL will call the "names" methods on NameSearchResults objects.
# Return the object itself, which is an array.
class Name::Search::Results < Array
  def names
    self
  end
end
