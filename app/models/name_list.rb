class NameList < Array
  # GQL will call the "names" methods on NameList objects.
  # Return the object itself, which is an array.
  def names
    self
  end

end
