require 'rubygems'
require 'test/unit'
require 'fakefs/safe'
Dir[File.dirname(__FILE__) + '/../classes/*'].each do |f|
  require f
end

class TestFileProcessor < Test::Unit::TestCase
  def test_verify_filename
    [
      [ {}, {}, [ false, {}, {} ] ],
      [
        { 'file' => 'test' },
        {},
        [ true, { 'file' => 'test' }, 'test' ]
      ],
      [
        { 'blank' => true },
        { 'Meow' => { 'is_paginated' => false } },
        [ false, {}, { 'blank' => true } ],
      ],
      [
        { 'blank' => true },
        { 'Meow' => { 'is_paginated' => true } },
        [ false, {}, { 'blank' => true } ],
        {
          'Meow' => [ nil ]
        }
      ],
      [
        'test',
        {},
        [ true, {}, 'test' ]
      ],
      [
        'test.svg',
        {
          'Global' => { 'match' => '.*\.svg' }
        },
        [ Regexp.new('.*\.svg').match('test.svg'), {}, 'test.svg' ]
      ]
    ].each do |filename, config, expected_return, expected_paginated_source_files|
      file_processor = FileProcessor.new(config)

      result = file_processor.verify_filename(filename)
      if expected_return[0].is_a? MatchData
        assert_equal expected_return[1..-1], result[1..-1]
        assert_equal expected_return[0].to_a, result[0].to_a
      else
        assert_equal expected_return, result
      end

      if expected_paginated_source_files
        assert_equal expected_paginated_source_files, file_processor.paginated_source_files
      end
    end
  end

  def test_build_filename_parts
    [
      [
        { 'Global' => { 'page_index_format' => '%02d' } },
        nil,
        { 'index' => 9, 'title' => '', 'page_index' => '10' }
      ],
      [
        { 'Global' => { 'page_index_format' => '%02d' } },
        Regexp.new('(.*)-(.*)').match('10-test'),
        { 'index' => 10, 'title' => 'test', 'page_index' => '10' }
      ],
      [
        { 'Global' => { 'page_index_format' => '%02d', 'title' => '{index}-{title}' } },
        Regexp.new('(.*)-(.*)').match('10-test'),
        { 'index' => 10, 'title' => '10-test', 'page_index' => '10' }
      ],
    ].each do |config, match_data, expected_result|
      file_processor = FileProcessor.new(config)
      file_processor.page_index = 10

      assert_equal expected_result, file_processor.build_filename_parts(match_data)
    end
  end

  def test_construct_filters_and_targets
    match_data = 'test'

    [
      [
        'test.svg',
        { 'target' => 'test.png' },
        'test',
        [ SVGToTempBitmap, TempBitmapToWeb, 'target' ]
      ],
      [
        'test.svg',
        { 'target' => 'test.pdf' },
        'test',
        [ SVGToTempBitmap, TempBitmapToPrint, 'target' ]
      ],
      [
        'test.svg',
        { 'target' => 'test.pdf', 'is_paginated' => true },
        'test',
        [ SVGToTempBitmap, TempBitmapToPaginatedPrint, 'target' ]
      ],
    ].each do |filename, info, match_data, expected_return|
      file_processor = FileProcessor.new({})
      file_processor.expects(:build_filename_parts).with(match_data).returns('parts')

      expected_return[0..1].each do |m|
        m.any_instance.stubs(:recalc_pixels)
      end

      expected_return[1].any_instance.expects(:targets).with('parts').returns('target')

      file_processor.construct_filters_and_targets(filename, info, match_data)
    end
  end

  def test_determine_rebuild
    [
      [ [], 'source', false ],
      [ [ 'r-test3' ], 'source', true ],
      [ [ 'r-test' ], 'source', true ],
      [ [ 'r-test2' ], 'source', false ],
      [ [ 'r-test2' ], 'blank', false ],
    ].each do |targets, filename, expected_return|
      file_processor = FileProcessor.new({})

      class << file_processor
        def file_mtime(file)
          case file
            when 'r-test'
              return 1
            when 'source'
              return 2
            when 'r-test2'
              return 3
          end
        end
      end

      FakeFS do
        FileUtils.touch [ 'r-test', 'r-test2', 'source' ]
        assert_equal expected_return, file_processor.determine_rebuild(targets, filename)
      end
    end
  end

  def test_do_build
    [
      [ 'target', 'input', 'return' ],
      [ [ 'target1', 'target2' ], 'input', [ 'return1', 'return2' ] ]
    ].each do |targets, filename, input_obj_build_return|
      input = Class.new do
        def build(filename); end
      end.new

      output = Class.new do
        def build(filename); end
      end.new

      input.expects(:build).with(filename).returns(input_obj_build_return)

      case input_obj_build_return.class.to_s
        when "String"
          output.expects(:build).with(input_obj_build_return, targets)
        when "Array"
          [0, 1].each do |i|
            output.expects(:build).with(input_obj_build_return[i], targets[i], (i == 0) ? "left" : "right")
          end
      end

      input.expects(:cleanup)

      file_processor = FileProcessor.new({})
      file_processor.do_build(targets, filename, input, output)
    end
  end
end
