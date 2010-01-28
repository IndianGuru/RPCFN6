require 'test/unit'
require 'utils'

class UtilsTest < Test::Unit::TestCase
  
  def test_each_combination_should_invoke
    c = []
    [1, 2, 3].each_combination { |combo| c << combo }
    assert_equal [[1], [1, 2], [1, 2, 3], [1, 3], [2], [2, 3]], c
  end

  def test_uniqueness_of_each_combination
    c = []
    [1, 2, 1].each_combination { |combo| c << combo }
    assert_equal [[1], [1, 2], [1, 2, 1], [1, 1]], c
  end
  
end
