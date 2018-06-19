# frozen_string_literal: true

# Work out which generator is needed.
class Taxonomy::Search::SqlGeneratorFactory
  def initialize(parser)
    @parser = parser
  end

  def build
    Rails.logger.debug("Taxonomy::Search::SqlGeneratorFactory#build....")
    name = ""
    name += 'Accepted' if @parser.accepted?
    name += 'Excluded' if @parser.excluded?
    name += 'CrossReference' if @parser.cross_reference?
    name += 'Accepted' if name.blank?
    Rails.logger.debug("Taxonomy::Search::SqlGeneratorFactory#build....name: #{name}")
    Rails.logger.debug("Taxonomy::Search::SqlGeneratorFactory::#{name}".constantize)
    "Taxonomy::Search::SqlGeneratorFactory::#{name}".constantize.new(@parser)
  end

  def xxbuild
    Rails.logger.debug("Taxonomy::Search::SqlGeneratorFactory#build....")
    name = ""
    name += 'Accepted' if @parser.accepted? || @parser.excluded?
    name += 'CrossReference' if @parser.cross_reference?
    name += 'Accepted' if name.blank?
    Rails.logger.debug("Taxonomy::Search::SqlGeneratorFactory#build....name: #{name}")
    Rails.logger.debug("Taxonomy::Search::SqlGeneratorFactory::#{name}".constantize)
    "Taxonomy::Search::SqlGeneratorFactory::#{name}".constantize.new(@parser)
  end
end
