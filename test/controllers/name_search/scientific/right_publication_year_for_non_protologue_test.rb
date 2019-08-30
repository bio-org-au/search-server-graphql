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
class NameSearchScientificRightPubYear4NonProtoTest < ActionController::TestCase
  tests GraphqlController
  setup do
  end

  test 'scientific name search on right iso publication date 4 non protologue' do
    post 'execute',
         params: { query: '{filteredNames(page:1, count:100, filter: {searchTerm:"angophora costata", isoPublicationDate: "1962", typeOfName:"scientific"}){data{id,full_name,name_usages{reference_details{citation,page,page_qualifier,year}}}}}' }
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
