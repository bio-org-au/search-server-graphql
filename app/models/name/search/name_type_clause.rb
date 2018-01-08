# frozen_string_literal: true

# Generate name type clause sql
class Name::Search::NameTypeClause
  SCIENTIFIC_CLAUSE = 'name_type.scientific or '
  SCIENTIFIC_CLAUSE_NOT_HYBRID = '(name_type.scientific and not name_type.hybrid) or '
  SCIENTIFIC_CLAUSE_NOT_AUTONYM = '(name_type.scientific and not name_type.autonym) or '
  SCIENTIFIC_CLAUSE_NOT_HYBRID_NOT_AUTONYM = '(name_type.scientific and not name_type.autonym and not name_type.hybrid) or '
  CULTIVAR_CLAUSE = 'name_type.cultivar or '
  AUTONYM_CLAUSE = 'name_type.autonym or '
  HYBRID_CLAUSE = '(name_type.scientific and name_type.hybrid) or '
  COMMON_CLAUSE = "name_type.name in ('common','informal','vernacular') or "

  def initialize(parser)
    @parser = parser
  end

  def clause
    buffer = String.new
    if @parser.scientific?
      if @parser.autonym? && @parser.hybrid?
        buffer << SCIENTIFIC_CLAUSE
      elsif @parser.autonym?
        buffer << SCIENTIFIC_CLAUSE_NOT_HYBRID
      elsif @parser.hybrid?
        buffer << SCIENTIFIC_CLAUSE_NOT_AUTONYM
      else
        buffer << SCIENTIFIC_CLAUSE_NOT_HYBRID_NOT_AUTONYM
      end
    else
      buffer << AUTONYM_CLAUSE if @parser.autonym?
      buffer << HYBRID_CLAUSE if @parser.hybrid?
    end
    buffer << CULTIVAR_CLAUSE if @parser.cultivar?
    buffer << COMMON_CLAUSE if @parser.common?
    buffer = buffer.sub(/ or $/,'')
    return "(1=2)" if buffer.blank?
    "(#{buffer})"
  end
end
