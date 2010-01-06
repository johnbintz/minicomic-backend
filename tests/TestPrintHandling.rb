require 'rubygems'
require 'test/unit'
require 'mocha'
require 'fakefs/safe'
require File.dirname(__FILE__) + '/../modules/PrintHandling.rb'

class TestPrintHandling < Test::Unit::TestCase
  def setup
    @instance = Class.new do
      include PrintHandling

      attr_accessor :config
    end.new
  end

  def test_calculate_page_size
    [
      [ { 'page_width' => 10, 'page_height' => 20 }, [ 10, 20 ] ],
      [ { 'dpi' => 100 , 'page_width' => 10, 'page_height' => 20 }, [ 10, 20 ] ],
      [ { 'dpi' => 100 , 'page_width_inches' => 1, 'page_height_inches' => 2 }, [ 100, 200 ] ],
      [ { 'dpi' => 1 , 'page_size' => 'letter' }, [ 8.5, 11 ] ],
      [ { 'dpi' => 1 , 'page_size' => 'letter_landscape' }, [ 11, 8.5 ] ],
      [ { 'dpi' => 1 , 'page_size' => 'half_letter_landscape' }, [ 5.5, 8.5 ] ],
    ].each do |config, expected_return|
      @instance.config = config
      assert_equal expected_return, @instance.calculate_page_size
    end
  end
end
