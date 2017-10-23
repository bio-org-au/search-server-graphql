# frozen_string_literal: true

# Class that runs about searches
class Settings::Search
  attr_reader :value
  def initialize(args)
    @search_term = args[:search_term]
  end

  def value
    ShardConfig.where(['name = ? ',@search_term]).first.value
  rescue
    'Unknown'
  end
end
