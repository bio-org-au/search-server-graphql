# frozen_string_literal: true

# Generate name type clause sql
class Reference::Search::NameTypeClause
  SCIENTIFIC_CLAUSE_OR = 'name_type.scientific or '
  SCIENTIFIC_CLAUSE_NOT_HYBRID_OR = '(name_type.scientific and not name_type.hybrid) or '
  SCIENTIFIC_CLAUSE_NOT_AUTONYM_OR = '(name_type.scientific and not name_type.autonym) or '
  SCIENTIFIC_CLAUSE_NOT_HYBRID_NOT_AUTONYM_OR = '(name_type.scientific and not name_type.autonym and not name_type.hybrid) or '
  CULTIVAR_CLAUSE_OR = 'name_type.cultivar or '
  AUTONYM_CLAUSE_OR = 'name_type.autonym or '
  HYBRID_CLAUSE_OR = '(name_type.scientific and name_type.hybrid) or '
  COMMON_CLAUSE_OR = "name_type.name in ('common','informal','vernacular') or "

  def initialize(parser)
    @parser = parser
  end

  def clause
    buffer = String.new
    if @parser.scientific?
      buffer << if @parser.autonym? && @parser.hybrid?
                  SCIENTIFIC_CLAUSE_OR
                elsif @parser.autonym?
                  SCIENTIFIC_CLAUSE_NOT_HYBRID_OR
                elsif @parser.hybrid?
                  SCIENTIFIC_CLAUSE_NOT_AUTONYM_OR
                else
                  SCIENTIFIC_CLAUSE_NOT_HYBRID_NOT_AUTONYM_OR
                end
    else
      buffer << AUTONYM_CLAUSE_OR if @parser.autonym?
      buffer << HYBRID_CLAUSE_OR if @parser.hybrid?
    end
    buffer << CULTIVAR_CLAUSE_OR if @parser.cultivar?
    buffer << COMMON_CLAUSE_OR if @parser.common?
    buffer << SCIENTIFIC_CLAUSE_OR if buffer.blank?
    buffer = buffer.sub(/ or $/, '')
    "(#{buffer})"
  end
end
