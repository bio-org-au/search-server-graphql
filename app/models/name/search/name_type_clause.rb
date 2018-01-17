# frozen_string_literal: true

# Generate name type clause sql
class Name::Search::NameTypeClause
  # Note: a named hybrid is a hybrid that is not a formula.
  SCIENTIFIC_CLAUSE_OR = 'name_type.scientific or '
  SCIENTIFIC_CLAUSE_NOT_NAMED_HYBRID_OR = '(name_type.scientific and not (name_type.hybrid and not name_type.formula)) or '
  SCIENTIFIC_CLAUSE_NOT_AUTONYM_OR = '(name_type.scientific and not name_type.autonym) or '
  SCIENTIFIC_CLAUSE_NOT_NAMED_HYBRID_NOT_AUTONYM_OR = '(name_type.scientific and not name_type.autonym and not (name_type.hybrid and not name_type.formula)) or '
  CULTIVAR_CLAUSE_OR = 'name_type.cultivar or '
  AUTONYM_CLAUSE_OR = 'name_type.autonym or '
  NAMED_HYBRID_CLAUSE_OR = '(name_type.scientific and (name_type.hybrid and not name_type.formula)) or '
  COMMON_CLAUSE_OR = "name_type.name in ('common','informal','vernacular') or "

  def initialize(parser)
    @parser = parser
  end

  def clause
    buffer = String.new
    if @parser.scientific?
      if @parser.autonym? && @parser.named_hybrid?
        buffer << SCIENTIFIC_CLAUSE_OR
      elsif @parser.autonym?
        buffer << SCIENTIFIC_CLAUSE_NOT_NAMED_HYBRID_OR
      elsif @parser.named_hybrid?
        buffer << SCIENTIFIC_CLAUSE_NOT_AUTONYM_OR
      else
        buffer << SCIENTIFIC_CLAUSE_NOT_NAMED_HYBRID_NOT_AUTONYM_OR
      end
    else
      buffer << AUTONYM_CLAUSE_OR if @parser.autonym?
      buffer << NAMED_HYBRID_CLAUSE_OR if @parser.named_hybrid?
    end
    buffer << CULTIVAR_CLAUSE_OR if @parser.cultivar?
    buffer << COMMON_CLAUSE_OR if @parser.common?
    buffer << SCIENTIFIC_CLAUSE_OR if buffer.blank?
    buffer = buffer.sub(/ or $/,'')
    "(#{buffer})"
  end
end
