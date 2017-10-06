# frozen_string_literal: true

# Attributes for synonym type.
class InstanceAsSynonym < ApplicationRecord
  self.table_name = "instance"
  self.primary_key = "id"
  belongs_to :instance, foreign_key: "cited_by_id"
  belongs_to :name
  belongs_to :reference
  belongs_to :cite, foreign_key: "cites_id"
  belongs_to :this_cites,
             class_name: "Instance",
             foreign_key: "cites_id"
  belongs_to :instance_type
  scope :in_nested_instance_type_order, (lambda do
    order(
      "          case instance_type.name " \
      "          when 'basionym' then 1 " \
      "          when 'replaced synonym' then 2 " \
      "          when 'common name' then 99 " \
      "          when 'vernacular name' then 99 " \
      "          else 3 end, " \
      "          case nomenclatural " \
      "          when true then 1 " \
      "          else 2 end, " \
      "          case taxonomic " \
      "          when true then 2 " \
      "          else 1 end "
    )
  end)


# end
  
  # attr_reader :id, :full_name, :instance_type, :page, :label,
              # :page, :page_qualifier

  # def initialize(instance, has_or_of_label = 'has')
    # @id = instance[:instance_id]
    # @instance_type = instance[:instance_type_name]
    # if has_or_of_label == 'has'
      # @label = instance[:instance_type_has_label]
      # @full_name = instance[:name_full_name]
    # else
      # @label = instance[:instance_type_of_label]
      # @full_name = Instance.find(Instance.find(@id).cited_by_id).name.full_name
    # end
    # @page = instance[:page]
    # @page_qualifier = instance[:page_qualifier]
  # end
end
