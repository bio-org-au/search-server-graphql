class NameSearchResults < Array
  # GQL will call the "names" methods on NameSearchResults objects.
  # Return the object itself, which is an array.
  def names
    self
  end

end
