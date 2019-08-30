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
class NameSearchAllSimpleTest < ActionController::TestCase
  tests GraphqlController
  setup do
    @args = +'filteredNames(count: 100, page: 1, filter: {searchTerm:"a*", '
    @args << 'scientificName: true,'
    @args += 'scientificAutonymName: true,scientificNamedHybridName: true,'
    @args += 'cultivarName: true, commonName: true})'
    @fields = +'{data{id,full_name,name_usages{reference_details'
    @fields += '{citation,page,page_qualifier,year}}}}'
  end

  test 'simple all name search test' do
    post 'execute', params: { query: "{#{@args}#{@fields}}" }
    assert_response :success
    obj = JSON.parse(response.body.to_s, object_class: OpenStruct)
    assert obj.data.filteredNames.data.size > 20,
           'Should find at least 21 records'
    assert :success, 'Search should run'
  end
end
