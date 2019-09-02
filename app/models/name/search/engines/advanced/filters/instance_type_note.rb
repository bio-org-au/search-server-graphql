# frozen_string_literal: true

# Add a filter to the sql to answer a request.
class Name::Search::Engines::Advanced::Filters::InstanceTypeNote
  PARAMETER = 'typeNoteText'
  SELECT = 'select id from author where '
  CLAUSE = "( name.author_id in (#{SELECT} lower(abbrev) like lower(?)))"

  def initialize(incoming_sql, parser)
    @incoming_sql = incoming_sql
    @parser = parser
  end

  def sql
    return @incoming_sql if parameter.blank?

    @incoming_sql = @incoming_sql.where(["exists ( select null from instance where instance.name_id =  name.id and exists (select null from instance_note inote where lower(value) like lower(?) and inote.instance_id = instance.id and inote.instance_note_key_id in (select id from instance_note_key ink where ink.name in (#{list_of_type_notes_allowed}))))", '%' + parameter + '%'])
  end

  def parameter
    return nil unless @parser.text_arg?(PARAMETER)

    @parser.args[PARAMETER].strip.tr('*', '%').gsub(/×/, 'x')
  end

  def list_of_type_notes_allowed
    note_types = []
    note_types.push "'Type'" if @parser.type_note_type?
    note_types.push "'Neotype'" if @parser.type_note_neotype?
    note_types.push "'Lectotype'" if @parser.type_note_lectotype?
    note_types.join(',')
  end
end
