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

  test 'runtime environment test' do
    skip
    # post 'execute', params: { query: '{ runtime_environment {ruby_platform, ruby_version, rails_version, database} }' }
    # assert_response :success
    # obj = JSON.parse(response.body.to_s, object_class: OpenStruct)
    # assert_not obj.data.runtime_environment.ruby_platform.nil?, msg("platform")
    # assert_not obj.data.runtime_environment.ruby_version.nil?, msg("ruby vers")
    # assert_not obj.data.runtime_environment.rails_version.nil?, msg("rails ver")
    # assert_not obj.data.runtime_environment.database.nil?, msg("database")
  end

  def msg(thing)
    "Should show #{thing}"
  end
end
