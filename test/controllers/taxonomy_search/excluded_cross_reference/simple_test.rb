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
class TaxonomySearchExcludedCrossRefNameSimpleTest < ActionController::TestCase
  tests GraphqlController
  setup do
  end

  test 'simple excluded cross reference name taxonomy query test' do
    post 'execute',
         params: { query: '{taxonomy_search(search_term:"angophora costata", excluded_name: true, cross_reference: true){count,taxa{id,full_name}}}' }
    assert_response :success
    obj = JSON.parse(response.body.to_s, object_class: OpenStruct)
    assert obj.errors.blank?, "Error: #{obj.errors.try('first').try('message')}"
    # no tree fixtures yet, so expect no results
    # puts response.body
    # assert_match 'Angophora',
    #              obj.data.taxonomy_search.taxa.first.full_name,
    #              "Taxon name should match 'Angophora'"
  end
end

