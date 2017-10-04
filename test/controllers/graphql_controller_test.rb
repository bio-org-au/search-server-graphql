# frozen_string_literal: true

#   Copyright 2017 Australian National Botanic Gardens
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
require 'test_helper'

# Graphql controller tests
class GraphqlControllerTest < ActionController::TestCase
  setup do
  end

  test "should be a minimal test" do
    puts "should be a minimal test"
    post 'execute'
    assert_response :success
    puts response.body
  end

  test "simple taxonomy query test" do
    puts "simple taxonomy query test"
    post 'execute',
      {query: '{taxonomy_search(search_term:"angophora"){taxa{id,full_name,name_status_name}}}' }
    assert_response :success
    puts response.body
    # {"data":{"taxonomy_search":{"taxa":[]}}}
  end
    #params: {"query"=>"{ taxonomy_search(search_term: \"angophora costata\",          type_of_name: \"scientific\") {taxa {id, simple_name, full_name, name_status_name, reference_citation}}}", "variables"=>nil, "operationName"=>nil, "graphql"=>{"query"=>"{taxonomy_search(search_term: \"angophora costata\",type_of_name: \"scientific\") {taxa {id,simple_name,full_name,name_status_name,reference_citation}}}", "variables"=>nil, "operationName"=>nil}}
end
