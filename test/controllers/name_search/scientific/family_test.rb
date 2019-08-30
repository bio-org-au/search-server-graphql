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
    @args = '{filteredNames(page:1, count:100, filter: {searchTerm:"myrtaceae", typeOfName: "scientific")'
    @fields = '{count,names{id,fullName,nameUsages'
    @fields += '{referenceDetails{citation,page,pageQualifier,year}}}}}}'
  end

  test 'scientific name search on family' do
    post 'execute', params: { query: "#{@args}#{@fields}" }
    assert_response :success
    # We have no name_tree_path fixtures,so the query returns no records.
    # obj = JSON.parse(response.body.to_s, object_class: OpenStruct)
    # assert obj.errors.nil?, "Not expecting any errors but got: #{obj.errors}."
    # expected = /\AAngophora lanceolata Cav.\z/
    # actual = obj.data.filteredNames.data.first.full_name
    # assert_match expected, actual,
    #              "Actual name #{actual} should match #{expected}"
  end
end
