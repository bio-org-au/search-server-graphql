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
class NameSearchScientificSimpleTest < ActionController::TestCase
  tests GraphqlController
  setup do
  end

  test 'simple scientific name search test' do
    post 'execute',
         params: { query: '{name_search(search_term:"angophora*", scientific_name: true, scientific_autonym_name: true, scientific_named_hybrid_name: true){count,names{id,full_name,name_usages{reference_usage{citation,page,page_qualifier,year,standalone}}}}}' }
    assert_response :success
    obj = JSON.parse(response.body.to_s, object_class: OpenStruct)
    assert_match 'Angophora',
                 obj.data.name_search.names.first.full_name,
                 "Name should match 'Angophora'"
  end
end
