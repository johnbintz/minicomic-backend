require 'rubygems'
require 'test/unit'
require 'fakefs/safe'
require File.dirname(__FILE__) + '/../classes/SVGToTempBitmap.rb'

class TestSVGToTempBitmap < Test::Unit::TestCase
  def setup
    @filter = SVGToTempBitmap.new
  end

  def test_build
    [
      [ "", :single ],
      [ [], :multiple ]
    ].each do |input, expected_method|
      @filter.expects(expected_method).with(input)
      @filter.build(input)
    end
  end

  def test_build_spread
    @filter.stubs(:get_dimensions).with('filename').returns([50, 75])
    @filter.expects(:convert).with(['"filename"', '-gravity Northwest', '-crop 25x75+0+0', '+repage', '"filename-left.png"'])
    @filter.expects(:convert).with(['"filename"', '-gravity Northwest', '-crop 25x75+25+0', '+repage', '"filename-right.png"'])

    assert_equal [ 'filename-left.png', 'filename-right.png' ], @filter.build_spread('filename')
  end
end
