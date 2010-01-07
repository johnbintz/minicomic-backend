require 'rubygems'
require 'test/unit'
require 'mocha'
require File.dirname(__FILE__) + '/../classes/TempBitmapToWeb.rb'

class TestTempBitmapToWeb < Test::Unit::TestCase
  def setup
    @filter = TempBitmapToWeb.new
    @filter.stubs(:convert_pixels)
  end

  def test_build
    [
      [ nil, 80 ],
      [ 75,  75 ]
    ]. each do |quality, expected_quality|
      @filter.expects(:convert).with("\"file\" -quality #{expected_quality} \"outfile\"")
      @filter.config = {
        'quality' => quality
      }
      @filter.build('file', 'outfile')
    end
  end

  def test_requires_schedule
    @filter.requires_schedule('test')
    assert_equal 'test', @filter.schedule
  end

  def test_filename
    @filter.schedule = [ Date.parse('2010-01-01') ]
    @filter.config = {
      'target' => 'test{date}',
      'date_format' => '%Y-%m-%d'
    }
    assert_equal 'test2010-01-01', @filter.filename({'index' => 0})
  end

end
