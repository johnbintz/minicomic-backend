require 'rubygems'
require 'test/unit'
require 'fakefs/safe'
require File.dirname(__FILE__) + '/../classes/Filter.rb'

class TestFilter < Test::Unit::TestCase
  def setup
    @filter = Filter.new
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

    @filter.config = {
      'print' => true,
      'dpi' => 10,
      'width_inches' => 1,
      'height_inches' => 2
    }
    assert_equal(10, @filter.config['width'])
    assert_equal(20, @filter.config['height'])
  end

  def test_cleanup
    @filter.cleanup = [ 'test', 'test2', 'test3' ]
    FakeFS do
      FileUtils.touch [ 'test', 'test3', 'test4' ]
      @filter.cleanup

      [ 'test', 'test2', 'test3' ].each do |file|
        assert !(File.exists? file)
      end

      [ 'test4' ].each do |file|
        assert File.exists? file
      end
    end
  end

  def test_get_dimensions
    assert_equal [ 50, 75 ], @filter.get_dimensions(File.dirname(__FILE__) + '/data/test_dimensions.png')
  end
end
