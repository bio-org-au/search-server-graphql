# frozen_string_literal: true

# GQL will call the "names" methods on TaxonomySearchResults objects.
# Return the object itself, which is an array.
class Taxonomy::Search::Results < Array
  def taxa
    self
  end
end
