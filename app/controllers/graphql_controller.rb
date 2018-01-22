# frozen_string_literal: true

# Controller for Graphql calls.
class GraphqlController < ApplicationController
  def execute
    @start_time = Time.now
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      # Query context goes here, for example:
      # current_user: current_user,
    }
    @result = Schema.execute(query, variables: variables,
                                    context: context,
                                    operation_name: operation_name)

    record_metadata
    render json: @result
  rescue => e
    Rails.logger.error("Error rescue at GraphqlController#execute: #{e}")
    Rails.logger.error('Backtrace below')
    e.backtrace.each { |b| Rails.logger.error(b) }
    Rails.logger.error('End of backtrace. Now render the error as JSON.')
    # Standard error format for our JSON
    render json: { errors: [{ message: e.to_s }] }
  end

  private

  # Handle form data, JSON body, or a blank value
  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end

  def record_metadata
    size = ''
    data = @result['data']
    name_search = data['name_search'] unless data.blank?
    names = name_search['names'] unless name_search.blank?
    size = names.size unless names.blank?
    Rails.logger.debug("query: #{params[:query]}; @result.size: #{size}; elapsed: #{(Time.now - @start_time).round(3)}")
  end
end
