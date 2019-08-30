# frozen_string_literal: true

# Work out which generator is needed.
class Taxonomy::Search::SqlGeneratorFactory
  def initialize(parser)
    @parser = parser
  end

  def build
    debug("build")
    name = ""
    name += 'Accepted' if @parser.accepted?
    name += 'Excluded' if @parser.excluded?
    name += 'CrossReference' if @parser.cross_reference?
    name += 'Accepted' if name.blank?
    debug("build....name: #{name}")
    debug("Taxonomy::Search::SqlGeneratorFactory::#{name}".constantize)
    "Taxonomy::Search::SqlGeneratorFactory::#{name}".constantize.new(@parser)
  end

  private

  def debug(msg)
    Rails.logger.debug("Taxonomy::Search::SqlGeneratorFactory: #{msg}")
  end
end
