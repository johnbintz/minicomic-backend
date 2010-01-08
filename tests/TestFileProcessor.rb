require 'rubygems'
require 'test/unit'
require File.dirname(__FILE__) + '/../classes/FileProcessor.rb'

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

  end
end
