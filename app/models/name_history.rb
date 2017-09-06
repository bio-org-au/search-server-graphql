class NameHistory
  attr_reader :name_usages, :synonym_bunch

  def initialize(name_id)
    @name = Name.find(name_id)
    raw_results = NameUsageQuery.new(name_id).results
    Rails.logger.debug(raw_results.class)
    Rails.logger.debug(raw_results.class)
    Rails.logger.debug(raw_results.class)
    instance_ids = raw_results.map(&:instance_id)
    Rails.logger.debug(' NameHistory =====================================================================')
    Rails.logger.debug(' NameHistory =====================================================================')
    Rails.logger.debug(' NameHistory =====================================================================')
    Rails.logger.debug(instance_ids.join(','))
    Rails.logger.debug(' NameHistory =====================================================================')
    Rails.logger.debug(' NameHistory =====================================================================')
    Rails.logger.debug(' NameHistory =====================================================================')
    @synonym_bunch = SynonymBunchQuery.new(instance_ids)
    Rails.logger.debug(" NameHistory @synonym_bunch.class: #{@synonym_bunch.class}")
    unless @synonym_bunch.results.empty?
      Rails.logger.debug(" NameHistory  @cited_by_id:  #{@synonym_bunch.results.first[:cited_by_id]} =====================================================================")
    end
    @name_usages = raw_results.collect do |usage|
      NameUsage.new(usage, @synonym_bunch)
    end
  end
end
