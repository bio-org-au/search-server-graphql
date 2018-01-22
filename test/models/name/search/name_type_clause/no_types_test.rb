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

class NoTypeParserDummy
  def scientific?
    false
  end

  def autonym?
    false
  end

  def hybrid_formula?
    false
  end

  def named_hybrid?
    false
  end

  def cultivar?
    false
  end

  def common?
    false
  end
end

# Single controller test.
class NameSeachNameTypeClauseNoTypesTest < ActionController::TestCase
  setup do
    @parser = NoTypeParserDummy.new
  end

  test 'name search name type clause no types provided' do
    expected = /\A\(name_type.scientific\)\z/
    actual = Name::Search::NameTypeClause.new(@parser).clause
    assert_match expected, actual,
                 %(Clause: "#{actual}" not as expected: "#{expected}")
  end
end
