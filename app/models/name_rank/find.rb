# frozen_string_literal: true

# Class that find an Author matching a URI
# The instance object must respond to these methods:
# - id (uri)
# - fullName: String
# - standardForm: String
# - ipniId: String
# - name: String
class NameRank::Find
  def initialize(args)
    id = args['id']
    @name_rank = NameRank.find_by(id: id)
    raise 'no matching name rank' if @name_rank.nil?
  end

  def method_missing(name, *args, &block)
    @name_rank.send(name)
  end

  private

  def debug(msg)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("NameRank::Find: #{msg}")
    Rails.logger.debug('==============================================')
  end
end
