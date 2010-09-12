require 'test_helper'
require 'minicomic-backend/output_filter'

class TestOutputFilter < Test::Unit::TestCase
  def setup
    @of = OutputFilter.new
    @of.stubs(:recalc_pixels)
  end

  def test_filename
    @of.config = { 'target' => 'test{test}{test2}test3' }
    assert_equal 'testtest4test5test3', @of.filename({ 'test' => 'test4', 'test2' => 'test5' })
  end
end

