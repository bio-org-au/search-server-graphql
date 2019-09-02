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
    @author = Author.find_by(id: uri.split('/').last)
    raise 'no matching author' if @author.nil?
  end

  private

  def method_missing(name, *_args)
    @author.send(name)
  end

  def debug(msg)
    Rails.logger.debug("Author::Find: #{msg}")
  end
end
