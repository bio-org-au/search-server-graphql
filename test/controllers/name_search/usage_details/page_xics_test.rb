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
class NameSearchUsageDetailsPageXicsTest < ActionController::TestCase
  tests GraphqlController
  setup do
    @query_string = '{filteredNames(filter: {searchTerm:"angophora costata*", '
    @query_string += 'scientificName: true, scientificAutonymName: true, '
    @query_string += 'scientificNamedHybridName: true})'
    @query_string += '{data{id,full_name,name_usages{reference_details'
    @query_string += '{citation,page, page_qualifier,year}}}}}'
    @target = 'Britten, J., (1916) Journal of Botany, British and Foreign. 54'
  end

  test 'name search usage details page xics' do
    post 'execute',
         params: { query: @query_string }
    assert_response :success
    obj = JSON.parse(response.body.to_s, object_class: OpenStruct)
    assert_match(/^Angophora costata \(Gaertn.\) Britten$/,
                 obj.data.filteredNames.data.first.full_name,
                 "Expecting 'Angophora costata (Gaertn.) Britten'")
    obj.data.filteredNames.data.first.name_usages.each do |usage|
      next unless usage.reference_details.citation == @target

      assert_match(/^xx 15–18$/,
                   usage.reference_details.page,
                   'Expecting an en dash in the page data.')
    end
  end
end
