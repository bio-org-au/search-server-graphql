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
class NameSearchScientificWrongPubYear4ProtoTest < ActionController::TestCase
  tests GraphqlController
  setup do
    query_call = 'filteredNames(page:1, count:100, filter:  '
    filter = +'{searchTerm:"angophora costata", publication: "%",'
    filter << 'isoPublicationDate: "1962", protologue: true,'
    filter << 'typeOfName:"scientific"})'
    fields = +'{data{id,full_name,name_usages{reference_details'
    fields << '{citation,page,page_qualifier,year}}}}'
    @query_str = "{ #{query_call}#{filter}#{fields} }"
    puts @query_str
  end

  test 'scientific name search on wrong iso publication date 4 protologue' do
    post 'execute',
         params: { query: @query_str }
    assert_response :success
    obj = JSON.parse(response.body.to_s, object_class: OpenStruct)
    assert obj.errors.nil?, "Not expecting any errors but got: #{obj.errors}."
    assert obj.data.filteredNames.data.blank?, 'Should be no names returned.'
    assert_equal 0, obj.data.filteredNames.data.size,
                 'Should be no names counted.'
  end
end
