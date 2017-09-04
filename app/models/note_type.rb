class NoteType
  attr_reader id, key, value 
  def initialize(raw_note)
    @id = raw_note.id
    @key = raw_note.key
    @value = raw_note.value
  end
end

