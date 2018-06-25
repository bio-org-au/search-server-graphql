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

  test 'should be a minimal test' do
    post 'execute'
    assert_response :success
  end

  # unknown OID 705: failed to recognize type of 'cross_referenced_full_name'. It will be treated as String.
  test 'simple taxonomy query test' do
    post 'execute',
         params: { query: '{taxonomy_search(search_term:"angophora"){taxa{id,full_name,name_status_name}}}' }
    assert_response :success
  end
end
