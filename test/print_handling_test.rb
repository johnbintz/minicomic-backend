require 'test_helper'
require 'minicomic-backend/print_handling'

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

  def test_build_for_print
    @instance.stubs(:calculate_page_size).returns([10, 20])
    @instance.config = { 'dpi' => 100 }
    [
      [ 'none', 'Center' ],
      [ 'left', 'East' ],
      [ 'right', 'West' ]
    ].each do |side, gravity|
      [
        [ '|pipe', 'pipe' ],
        [ 'nopipe', '"nopipe"' ]
      ].each do |output, expected_filename|
        @instance.expects(:convert).with([
          '-density 100',
          '-size 10x20',
          'xc:white',
          "-gravity #{gravity}",
          "-draw 'image Over 0,0 0,0 \"input\"'",
          expected_filename
        ])

        @instance.build_for_print('input', output, side)
      end
    end
  end
end
