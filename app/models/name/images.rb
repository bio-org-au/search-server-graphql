# frozen_string_literal: true

# Class that builds images structure
# TODO: receive a name object
class Name::Images
  def initialize(id)
    @id = id 
  end

  def results
    return nil unless images_supported?
    @name = Name.find(@id)
    return nil unless @name.name_rank.species_or_below?  
    return nil unless images_present?
    ostruct = OpenStruct.new
    ostruct.count = image_count
    ostruct.link = "#{Rails.configuration.image_display_url}#{CGI.escape(@name.simple_name)}"
    ostruct
  end

  def image_count
    Name::Services::Images.load unless Rails.cache.read("images").class == Hash
    Rails.cache.read("images")[@name.simple_name]
  rescue => e
    Rails.logger.error("Error in Name#image_count: #{e}")
    Rails.logger.error("Assuming image_count is 0")
    0
  end

  def images_supported?
    Rails.configuration.try("image_links_supported") || false
  end

  def images_present?
    (image_count || 0).positive?
  end


  private

  def debug(s)
    Rails.logger.debug("==============================================")
    Rails.logger.debug("Name::Images: #{s}")
    Rails.logger.debug("==============================================")
  end
end
