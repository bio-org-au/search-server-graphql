# frozen_string_literal: true

# Class that conducts name searches
# The instance object must respond to these methods:
# - names
# - count
class Name::Search::Base
  def initialize(args)
    debug('base')
    @args = args
    @parser = Name::Search::Parser.new(args)
    if @parser.simple?
      debug('simple')
      @search = Name::Search::Engines::Simple.new(args)
    else
      debug('advanced')
      @search = Name::Search::Engines::Advanced.new(args)
    end
  end

  def names
    if @parser.merge?
      Name::Search::Merge.new(@search.names).merge
    else
      @search.names
    end
  end

  def count
    @search.count
  end

  def total
    @search.total
  end

  private

  def debug(msg)
    Rails.logger.debug("Name::Search::Base: #{msg}")
  end
end
