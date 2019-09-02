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
class NameSearchScientificFamilyTest < ActionController::TestCase
  tests GraphqlController
  setup do
    filter = 'filter: {family:"a_family", typeOfName: "scientific"}'
    call = "filteredNames(page:1, count:100, #{filter})"
    ref_details = 'reference_details{citation,page,page_qualifier,year}'
    @fields = "{data{id,full_name,name_usages{#{ref_details}}}}"
    @query = "{#{call}#{@fields}}"
  end

  test 'scientific name search on family' do
    post 'execute', params: { query: @query }
    assert_response :success
    obj = JSON.parse(response.body.to_s, object_class: OpenStruct)
    assert obj.errors.nil?, "Not expecting any errors but got: #{obj.errors}."
    assert obj.data.filteredNames.data.size > 50, 'Expected plenty of names'
  end
end
