# frozen_string_literal: true

# Generate name type clause sql
class Name::Search::NameTypeClause
  def initialize(parser)
    @parser = parser
  end

  def clause
    if @parser.scientific?
      'name_type.scientific'
    elsif @parser.cultivar?
      'name_type.cultivar'
    elsif @parser.scientific_or_cultivar?
      '(name_type.cultivar or name_type.scientific)'
    elsif @parser.common?
      "name_type.name in ('common','informal','vernacular')"
    elsif @parser.name_type_all?
      '1=1'
    else
      throw 'Unknown name type'
    end
  end
end
