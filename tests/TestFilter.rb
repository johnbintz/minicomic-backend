require 'rubygems'
require 'test/unit'
require 'mockfs/override'
require File.dirname(__FILE__) + '/../classes/Filter.rb'

class TestFilter < Test::Unit::TestCase
  def setup
    @filter = Filter.instance
  end

  def test_recalc_pixels
    @filter.config = {}

    assert_raise RuntimeError do
      @filter.config = {'print' => true}
    end

    assert_raise RuntimeError do
      @filter.config = {'print' => true,
                        'dpi' => 'test'}
    end

    assert_raise RuntimeError do
      @filter.config = {
        'print' => true,
        'dpi' => 10
      }
    end

    [ 'width', 'height' ].each do |dim|
      assert_raise RuntimeError do
        @filter.config = {
          'print' => true,
          'dpi' => 10,
          'width' => 10
        }
      end

      @filter.config = {
        'width' => 10
      }
      assert_equal(10, @filter.config['width'])
    end
  end
end
