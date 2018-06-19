# frozen_string_literal: true

# Class that conducts name searches
# The instance object must respond to these methods:
# - names
# - count
class Name::Search::Base
  def initialize(args)
    @args = args
    @parser = Name::Search::Parser.new(args)
    if @parser.simple?
      @search = Name::Search::Engines::Simple.new(args)
    else
      @search = Name::Search::Engines::Advanced.new(args)
    end
  end

  def debug(s)
    Rails.logger.debug("==============================================")
    Rails.logger.debug("Name::Search::Base: #{s}")
    Rails.logger.debug("==============================================")
  end

  def names
    Name::Search::Merge.new(@search.names).merge
  end

  def count
    @search.count
  end

private

  def base_query
    Name.name_matches(@parser.search_term)
        .has_an_instance
  end
end

