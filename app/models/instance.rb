# frozen_string_literal: true

# Rails model
class Instance < ActiveRecord::Base
  self.table_name = 'instance'
  self.primary_key = 'id'

  belongs_to :name
  belongs_to :namespace
  belongs_to :instance_type
  belongs_to :reference
  belongs_to :this_is_cited_by,
             class_name: 'Instance',
             foreign_key: 'cited_by_id'
  belongs_to :this_cites,
             class_name: 'Instance',
             foreign_key: 'cites_id'


  belongs_to :citer_instance, class_name: 'Instance', foreign_key: 'cited_by_id'
  belongs_to :cited_instance, class_name: 'Instance', foreign_key: 'cites_id'

  has_many :instance_notes
  has_many :instance_notes_for_details, foreign_key: :instance_id
  has_many :instance_note_keys, through: :instance_notes
  has_many :instance_note_for_type_specimens
  has_one  :instance_note_for_distribution
  has_one  :instance_note_for_comment
  has_many :name_detail_commons
  has_one  :accepted_tree_comment, (lambda do
    where "instance_note_key_id = (select id from instance_note_key
          where name = 'APC Comment')"
  end),
           class_name: 'InstanceNote', foreign_key: 'instance_id'
  has_many :synonyms, foreign_key: "cited_by_id", class_name: 'Instance'
  has_one :accepted_name

  belongs_to :cited_by_instance, foreign_key: 'cited_by_id'
  belongs_to :namespace
  has_one :instance_resource_vw

  scope :in_nested_instance_type_order, (lambda do
    order(
      '          case instance_type.name ' \
      "          when 'basionym' then 1 " \
      "          when 'replaced synonym' then 2 " \
      "          when 'common name' then 99 " \
      "          when 'vernacular name' then 99 " \
      '          else 3 end, ' \
      '          case nomenclatural ' \
      '          when true then 99 ' \
      '          else 2 end, ' \
      '          case taxonomic ' \
      '          when true then 2 ' \
      '          else 1 end '
    )
  end)

  def citation
    # "this is citation for id: #{id}"
    reference.citation
  end

  def type
    instance_type.name
  end

  def sort_fields
    [reference.year || 9999,
     instance_type.primaries_first,
     reference.author.try('name') || 'x']
  end

  def standalone?
    cited_by_id.nil? && cites_id.nil?
  end

  def primary?
    instance_type.primary?
  end

  def acccepted_comment
    instance_notes.each do |note|
      return note.value if note.accepted_tree_comment?
    end
    nil
  end

  def accepted_tree_distribution
    instance_notes.each do |note|
      return note.value if note.accepted_tree_distribution?
    end
    nil
  end

  def has_protologue?
    instance_resource_vw.present?
  end

  def synonyms_for_display_just_commons
    synonyms.joins(:instance_type)
            .where("instance_type.name = 'common name'
                    or
                    instance_type.name = 'vernacular name'")
  end

  def name_html(synonym, core_name_html)
    name_html = %(#{core_name_html}<span class="name-status">#{synonym.name.status.name_to_show}</span>)
  end

  def synonyms_for_taxonomy_display
    synonyms.sort do |x, y|
      [x.instance_type.misapplied.to_s, x.name.full_name, x.try('this_cites').try('reference').try('year') || 9999] <=> [y.instance_type.misapplied.to_s, y.name.full_name, y.try('this_cites').try('reference').try('year') || 9999]
    end.collect do |synonym|
      constructed_entry_html = synonym.instance_type.doubtful? ? '?' : ''
      if synonym.instance_type.misapplied?
        for_misapplied = { cites_author_component: synonym.this_cites.name.author_component_of_full_name,
                           cites_page: synonym.this_cites.page,
                           cites_reference_citation: synonym.this_cites.reference.citation }
        constructed_entry_html += name_html(synonym, synonym.name.simple_name_html)
        constructed_entry_html += '&nbsp;<i>auct. non</i>'
        constructed_entry_html += "#{synonym.this_cites.name.author_component_of_full_name}:&nbsp;"
        constructed_entry_html += synonym.this_cites.reference.citation
        constructed_entry_html += ": #{synonym.this_cites.page}" unless synonym.this_cites.page.blank?
        constructed_entry_html += %(, <span class="pro-parte"><i>p.p.</i></span>) if synonym.instance_type.pro_parte?
      else
        for_misapplied = {}
        constructed_entry_html += name_html(synonym, synonym.name.full_name_html)
        constructed_entry_html += ', p.p.' if synonym.instance_type.pro_parte?
      end

      { doubtful: synonym.instance_type.doubtful?,
        misapplied: synonym.instance_type.misapplied?,
        pro_parte: synonym.instance_type.pro_parte?,
        constructed_entry_html: constructed_entry_html,
        for_misapplied: for_misapplied }
    end
  end
end
