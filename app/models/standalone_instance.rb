# Some instances are standalone.
class StandaloneInstance < ApplicationRecord
  self.table_name = 'instance'
  self.primary_key = 'id'
  belongs_to :name
  belongs_to :reference
  belongs_to :instance_type
  has_many :synonym_instances_cited_by,
           class_name: 'SynonymInstance',
           foreign_key: :cited_by_id

  def citation
    reference.citation
  end

  def instance_type_name
    instance_type.name
  end

  def primary_instance?
    instance_type.primary?
  end

  def is_primary_instance
    instance_type.primary?
  end
end
