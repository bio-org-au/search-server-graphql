# frozen_string_literal: true

# For a given instance ID, retrieve a set of ordered
# synonymy instance results suitable for displaying within a name usage.
class OldNameSearch
  attr_reader :results, :args
  def initialize(args)
    throw 'x'
    Rails.logger.debug("NameSearch start ==================================================")
    @args = args
    @results = []
    Name.find(args["id"])
    Rails.logger.debug("NameSearch endish ==================================================")
  end
end
