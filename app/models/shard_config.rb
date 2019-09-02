# frozen_string_literal: true

# Rails model
class ShardConfig < ActiveRecord::Base
  self.table_name = 'shard_config'
  self.primary_key = 'id'

  # This replaces a lot of repetitive methods
  # that take a "name" e.g. "tree_label" and
  # return the value for that name in shard_config.
  # We just have to remove the underscores to
  # convert from a method name to a shard_config name.
  def self.method_missing(method, *_args, &_block)
    name_string = method.to_s.tr('_', ' ')
    find_by(name: name_string).value
  rescue StandardError
    "No shard value for #{name_string}"
  end

  def self.classification_tree_key
    find_by(name: 'classification tree key').value
  rescue StandardError
    'classification tree key'
  end

  def self.name_label
    find_by(name: 'name label').value
  rescue StandardError
    'name label'
  end

  def self.name_tree_label
    find_by(name: 'name tree label').value
  end

  def self.banner_text
    find_by(name: 'banner text').value
  rescue StandardError
    'banner text'
  end

  def self.menu_label
    find_by(name: 'menu label').value
  rescue StandardError
    'menu label'
  end

  def self.description_html
    find_by(name: 'description html').value
  rescue StandardError
    'description html'
  end

  def self.tree_description_html
    find_by(name: 'tree description html').value
  rescue StandardError
    'tree description html'
  end

  def self.tree_label_text
    find_by(name: 'tree label text').value
  rescue StandardError
    'tree label text'
  end

  def self.tree_banner_text
    find_by(name: 'tree banner text').value
  rescue StandardError
    'description html'
  end

  def self.page_title
    find_by(name: 'page title').value
  rescue StandardError
    'page title'
  end

  def self.name_description_html
    find_by(name: 'name description html').value
  rescue StandardError
    'name description html'
  end

  def self.name_space
    find_by(name: 'name space').value
  rescue StandardError
    'name space'
  end

  def self.tree_search_help_text_html
    find_by(name: 'tree search help text html').value
  rescue StandardError
    'tree search help text html'
  end

  def self.name_search_help_text_html
    find_by(name: 'name search help text html').value
  rescue StandardError
    'name search help text html'
  end

  def self.services_path_name_element
    find_by(name: 'services path name element').value
  rescue StandardError
    'services path name element'
  end

  def self.services_path_tree_element
    find_by(name: 'services path tree element').value
  rescue StandardError
    'services path tree element'
  end

  def self.name_link_title
    find_by(name: 'name link title').value
  rescue StandardError
    'name link title'
  end

  def self.tree_link_title
    find_by(name: 'tree link title').value
  rescue StandardError
    'tree link title'
  end

  def self.menu_link_title
    find_by(name: 'menu link title').value
  rescue StandardError
    'menu link title'
  end

  def self.name_label_text
    find_by(name: 'name label text').value
  rescue StandardError
    'name label text'
  end

  def self.name_banner_text
    find_by(name: 'name banner text').value
  rescue StandardError
    'name banner text'
  end
end
