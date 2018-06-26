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

# Single controller test.
class NameCheckSearchSimpleTest < ActionController::TestCase
  tests GraphqlController
  setup do
    @args =  'name_check(names: ["angophora costata"], limit: 50)'
    @fields = '{ results_count, results_limited, names_checked_count, names_checked_limited, names_with_match_count, names_found_count, names_to_check_count results { search_term, found, index, matched_name_id, matched_name_full_name, matched_name_family_name, matched_name_family_name_id, matched_name_accepted_taxonomy_accepted, matched_name_accepted_taxonomy_excluded } }'
  end

  test 'simple name check query' do
    skip "Need to add tree fixtures to make this work."
    post 'execute', params: { query: "{#{@args}#{@fields}}" }
    assert_response :success
    obj = JSON.parse(response.body.to_s, object_class: OpenStruct)
    refute_match('"errors"', response.body, 'Should be no errors')
    #assert_match 'Angophora', obj.data.name_search.names.first.full_name
                 #"Name should match 'Angophora'"
  end
end
