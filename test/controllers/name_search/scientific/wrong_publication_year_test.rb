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
class NameSearchScientificWrongPublicationYearTest < ActionController::TestCase
  tests GraphqlController
  setup do
    filter = +'{searchTerm:"angophora costata", isoPublicationDate: "1917"'
    filter << ', typeOfName:"scientific"}'
    ref_details = +'{citation,page,page_qualifier,year}'
    data = +"{id,full_name,name_usages{reference_details#{ref_details}}}"
    @query = "{filteredNames(filter: #{filter}){data#{data}}}"
  end

  test 'scientific name search on wrong iso publication date' do
    post 'execute',
         params: { query: @query }
    assert_response :success
    obj = JSON.parse(response.body.to_s, object_class: OpenStruct)
    assert obj.errors.nil?, "Not expecting any errors but got: #{obj.errors}."
    assert obj.data.filteredNames.data.blank?, 'Should be no names returned.'
    assert_equal 0, obj.data.filteredNames.data.size,
                 'Should be no names counted.'
  end
end
