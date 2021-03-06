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
class NameSearchScientificRightPublicationYearTest < ActionController::TestCase
  tests GraphqlController
  setup do
    filter = +'filter: {searchTerm:"angophora costata", '
    filter << 'isoPublicationDate: "1916", typeOfName:"scientific"}'
    args = "(page:1, count:100, #{filter})"
    ref_detail_fields = 'citation,page,page_qualifier,iso_publication_date'
    ref_details = "reference_details{#{ref_detail_fields}}"
    name_usages = "name_usages {#{ref_details}}"
    data = "data {id,full_name,#{name_usages}}"
    @query = "{filteredNames#{args}{#{data}}}"
  end

  test 'scientific name search on right iso publication date' do
    post 'execute',
         params: { query: @query }
    assert_response :success
    obj = JSON.parse(response.body.to_s, object_class: OpenStruct)
    assert obj.errors.nil?, "Not expecting any errors but got: #{obj.errors}."
    assert obj.data.filteredNames.data.present?, 'Should be a name returned.'
    expected = /\AAngophora costata \(Gaertn.\) Britten\z/
    actual = obj.data.filteredNames.data.first.full_name
    assert_match expected, actual,
                 "Actual name #{actual} should match #{expected}"
  end
end
