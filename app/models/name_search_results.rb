# GQL will call the "names" methods on NameSearchResults objects.
# Return the object itself, which is an array.
class NameSearchResults < Array
  def names
    self
  end
end
