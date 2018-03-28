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
class RuntimeEnvironmentTest < ActionController::TestCase
  tests GraphqlController
  setup do
  end

  test 'query test' do
    post 'execute', params: { query: '{runtime_environment}' }
    assert_response :success
    obj = JSON.parse(response.body.to_s, object_class: OpenStruct)
    assert obj.data.runtime_environment =~ /Ruby platform/,
           "Should show Ruby platform."
    assert obj.data.runtime_environment =~ /Ruby version/,
           "Should show Ruby version."
    assert obj.data.runtime_environment =~ /Rails/, "Should show Rails."
    assert obj.data.runtime_environment =~ /Database/, "Should show Database."
  end
end
