# frozen_string_literal: true

# Class that find an Author matching a URI
# The instance object must respond to these methods:
# - id (uri)
# - fullName: String
# - standardForm: String
# - ipniId: String
# - name: String
class Author::Find
  def initialize(args)
    uri = args['id']
    @author = Author.find_by(uri: uri)
    raise 'no matching author' if @author.nil?
  end

  def uri
    @author.uri
  end

  def name
    @author.name
  end

  def abbrev
    @author.abbrev
  end

  def ipni_id
    @author.ipni_id
  end

  def full_name
    @author.full_name
  end

  private

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("Author::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
