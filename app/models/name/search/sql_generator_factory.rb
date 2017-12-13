# frozen_string_literal: true

# Generate the sql to answer a request.
class Name::Search::SqlGeneratorFactory
  def initialize(parser)
    @parser = parser
  end

  def build
    #NameElementSql.new(@parser)
    Default.new(@parser)
  end
end

