class Thing
  attr_reader :references

  def initialize(name_id)
    @name = Name.find(name_id)
    @references = []
    @name.instances.each do |instance|
      @references.push(OneNameUsage.new(instance.id))
    end
  end

  def self.find(_id)
    # @references = []
    # Name.find(id).references.each do |ref|
    # @references.push ref.citation
    # end
  end

  def things
    @references
  end
end
