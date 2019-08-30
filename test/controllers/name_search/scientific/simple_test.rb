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
         params: { query: '{filteredNames(page:1, count:100, filter: {searchTerm:"angophora*", scientificName: true, scientificAutonymName: true, scientificNamedHybridName: true}){data{id,full_name,name_usages{reference_details{citation,page,page_qualifier,year}}}}}' }
    assert_response :success
    obj = JSON.parse(response.body.to_s, object_class: OpenStruct)
    assert_match 'Angophora',
                 obj.data.filteredNames.data.first.full_name,
                 "Name should match 'Angophora'"
  end
end
