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
class AdvNameSearchArgsScNamedHybridTest < ActionController::TestCase
  tests GraphqlController
  setup do
    @query = '{name_search(search_term:"*", scientific_named_hybrid_name: true)'
    @query += '{count,names{id,full_name,name_history'
    @query += '{name_usages{citation,page,page_qualifier,year,standalone}}}}}'
  end

  test 'simple all name search test' do
    post 'execute', query: @query
    assert_response :success,
                    'Should allow for scientific_named_hybrid_name arg'
    obj = JSON.parse(response.body.to_s, object_class: OpenStruct)
    assert obj.data.name_search.names.size > 1,
           'Should find at least 1 record'
  end
end