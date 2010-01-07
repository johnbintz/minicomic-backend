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

  def test_join_files
    @filter.output_filename = 'test'
    [
      [ [], 1, [] ],
      [ ['file'], 1, [
        [ 'test-0.png', 0, 0 ]
      ] ],
      [ ['file', 'file2'], 1, [
        [ 'test-0.png', 0, 0 ],
        [ 'test-1.png', 0, 1 ],
      ] ],
      [ ['file', 'file2'], 2, [
        [ 'test-0.png', 0, 0 ],
        [ 'test-1.png', 1, 0 ],
      ] ],
      [ ['blank', 'file2'], 2, [
        [ 'test-1.png', 1, 0 ],
      ] ],
    ].each do |files, width, expected_output|
      @filter.stubs(:inkscape)
      assert_equal expected_output, @filter.join_files(files, width)
    end
  end

  def test_generate_joined_files_command
    [
      [ [], 100, 50, [], [] ],
      [
        [
          [ 'file', 0, 0 ]
        ], 100, 50, [
          [ 50, 25 ]
        ], [
          '"file" -geometry +25+12 -composite'
        ]
      ],
    ].each do |files, grid_width, grid_height, image_size_returns, expected_command|
      @filter.stubs(:get_dimensions).returns(*image_size_returns)

      assert_equal expected_command, @filter.generate_joined_files_command(files, grid_width, grid_height)
    end
  end

  def test_single_no_spread
    @filter.output_filename = 'test'
    @filter.expects(:inkscape).with('file', Dir.pwd + '/test')
    assert_equal Dir.pwd + '/test', @filter.single('file')
    assert_equal [ Dir.pwd + '/test' ], @filter.cleanup
  end

  def test_single_spread
    @filter.stubs(:recalc_pixels)
    @filter.output_filename = 'test'
    @filter.config = {
      'spread' => true
    }

    @filter.expects(:inkscape).with('file', Dir.pwd + '/test')
    @filter.expects(:build_spread).with(Dir.pwd + '/test').returns(['target1', 'target2'])

    @filter.single('file')
  end

  def test_multiple
    @filter.stubs(:recalc_pixels)
    @filter.output_filename = 'test'
    @filter.config = {
      'grid' => '2x1'
    }
    @filter.stubs(:calculate_page_size).returns([100,50])

    joined_files = [
      [ 'test-0.png', 0, 0 ],
      [ 'test-1.png', 1, 0 ]
    ]

    @filter.expects(:join_files).with(['file1', 'file2'], 2).returns(joined_files)
    @filter.expects(:generate_joined_files_command).with(joined_files, 50, 50).returns([
      'command-1', 'command-2'
    ])

    @filter.expects(:convert).with([
      '-size 100x50',
      'xc:white',
      'command-1',
      'command-2',
      '"test"'
    ])

    assert_equal 'test', @filter.multiple(['file1', 'file2'])
    assert_equal [ 'test-0.png', 'test-1.png', 'test' ], @filter.cleanup
  end

end
