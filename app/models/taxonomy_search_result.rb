class TaxonomySearchResult
  attr_reader :id, :full_name, :simple_name, :name_status_name,
              :reference_citation, :synonyms
  def initialize(h)
    @id = h[:id]
    @full_name = h[:full_name]
    @simple_name = h[:simple_name]
    @name_status_name = h[:name_status_name]
    @reference_citation = h[:reference_citation]
  end

  def synonyms
    open_struct = OpenStruct.new
    open_struct.id    = 77
    open_struct
  end
end
