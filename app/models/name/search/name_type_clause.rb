# frozen_string_literal: true

# Generate name type clause sql
class Name::Search::NameTypeClause
  # Note: a named hybrid is a hybrid that is not a formula.
  SCIENTIFIC_CLAUSE_OR = 'name_type.scientific or '
  SCIENTIFIC_CLAUSE_NOT_HYBRID_FORMULA_OR = '(name_type.scientific and not (name_type.hybrid and name_type.formula)) or '
  SCIENTIFIC_CLAUSE_NOT_NAMED_HYBRID_OR = '(name_type.scientific and not (name_type.hybrid and not name_type.formula)) or '
  SCIENTIFIC_CLAUSE_NOT_AUTONYM_OR = '(name_type.scientific and not name_type.autonym) or '
  SCIENTIFIC_CLAUSE_NOT_HYBRID_OR = '(name_type.scientific and not name_type.hybrid) or '
  SCIENTIFIC_CLAUSE_NOT_AUTONYM_NOT_HYBRID_FORMULA_OR = '(name_type.scientific and not name_type.autonym and not (name_type.hybrid and name_type.formula)) or '
  SCIENTIFIC_CLAUSE_NOT_AUTONYM_NOT_NAMED_HYBRID_OR = '(name_type.scientific and not name_type.autonym and not (name_type.hybrid and not name_type.formula)) or '
  SCIENTIFIC_CLAUSE_NOT_HYBRID_NOT_AUTONYM_OR = '(name_type.scientific and not name_type.hybrid and not name_type.hybrid) or '
  CULTIVAR_CLAUSE_OR = 'name_type.cultivar or '
  AUTONYM_CLAUSE_OR = 'name_type.autonym or '
  NAMED_HYBRID_CLAUSE_OR = '(name_type.scientific and (name_type.hybrid and not name_type.formula)) or '
  HYBRID_FORMULA_CLAUSE_OR = '(name_type.scientific and name_type.hybrid and name_type.formula) or '
  COMMON_CLAUSE_OR = "name_type.name in ('common','informal','vernacular') or "

  def initialize(parser)
    @parser = parser
  end

  def clause
    buffer = String.new
    if @parser.scientific?
      if @parser.autonym? && @parser.named_hybrid? && @parser.hybrid_formula?
        Rails.logger.debug('clause 1')
        buffer << SCIENTIFIC_CLAUSE_OR
      elsif @parser.autonym? && @parser.named_hybrid?
        Rails.logger.debug('clause 2')
        buffer << SCIENTIFIC_CLAUSE_NOT_HYBRID_FORMULA_OR
        Rails.logger.debug("buffer: #{buffer}")
      elsif @parser.autonym? && @parser.hybrid_formula?
        Rails.logger.debug('clause 3')
        buffer << SCIENTIFIC_CLAUSE_NOT_NAMED_HYBRID_OR
      elsif @parser.named_hybrid? && @parser.hybrid_formula?
        Rails.logger.debug('clause 4')
        buffer << SCIENTIFIC_CLAUSE_NOT_AUTONYM_OR
      elsif @parser.autonym?
        Rails.logger.debug('clause 5')
        buffer << SCIENTIFIC_CLAUSE_NOT_HYBRID_OR
      elsif @parser.named_hybrid?
        Rails.logger.debug('clause 6')
        buffer << SCIENTIFIC_CLAUSE_NOT_AUTONYM_NOT_HYBRID_FORMULA_OR
      elsif @parser.hybrid_formula?
        Rails.logger.debug('clause 7')
        buffer << SCIENTIFIC_CLAUSE_NOT_AUTONYM_NOT_NAMED_HYBRID_OR
      else
        Rails.logger.debug('clause 8')
        buffer << SCIENTIFIC_CLAUSE_NOT_HYBRID_NOT_AUTONYM_OR
      end
    else
      Rails.logger.debug('clause 9')
      buffer << AUTONYM_CLAUSE_OR if @parser.autonym?
      buffer << NAMED_HYBRID_CLAUSE_OR if @parser.named_hybrid?
      buffer << HYBRID_FORMULA_CLAUSE_OR if @parser.hybrid_formula?
    end
    buffer << CULTIVAR_CLAUSE_OR if @parser.cultivar?
    buffer << COMMON_CLAUSE_OR if @parser.common?
    buffer << SCIENTIFIC_CLAUSE_OR if buffer.blank?
    Rails.logger.debug("lower buffer: #{buffer}")
    buffer = buffer.sub(/ or *$/, '')
    Rails.logger.debug("end buffer: #{buffer}")
    "(#{buffer})"
  end
end
