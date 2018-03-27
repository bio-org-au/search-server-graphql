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
class RanksOptionsTest < ActionController::TestCase
  tests GraphqlController
  setup do
  end

  test 'ranks query test' do
    post 'execute', params: { query: '{ranks{options}}' }
    assert_response :success
    obj = JSON.parse(response.body.to_s, object_class: OpenStruct)
    assert obj.data.ranks.present?, 'Ranks should be there'
    assert obj.data.ranks.options.present?, 'Ranks options should be there'
    assert_same Array, obj.data.ranks.options.class,
                'Options should be an Array'
    assert obj.data.ranks.options.size > 25, 'Should be at least 25 ranks.'
  end
end
