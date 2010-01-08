require 'rubygems'
require 'test/unit'
require File.dirname(__FILE__) + '/../classes/ConfigLoader.rb'

class TestConfigLoader < Test::Unit::TestCase
  def setup
    @config_loader = ConfigLoader.new
  end

  def test_load
    [
      [ {}, false, nil, nil ],
      [ {'Global' => {}}, false, nil, nil ],
      [
        {
          'Global' => {
            'path' => 'test/*.svg'
          }
        },
        {
          'Global' => {
            'path' => 'test/*.svg',
            'page_index_format' => '%02d',
            'files' => [],
            'fileinfo_by_file' => {}
          }
        },
        [
          { :expects => :count_pattern, :with => 'test/*.svg', :returns => '%02d' }
        ],
        nil
      ],
      [
        {
          'Global' => {
            'path' => '*.svg',
            'match' => '.*\.svg',
            'page_index_format' => '%02d'
          }
        },
        {
          'Global' => {
            'path' => '*.svg',
            'match' => '.*\.svg',
            'page_index_format' => '%02d',
            'files' => [ Dir.pwd + '/test1.svg', Dir.pwd + '/test2.svg' ],
            'fileinfo_by_file' => {}
          }
        },
        [],
        [ 'test1.svg', 'test2.svg', 'test3.png' ]
      ],
      [
        {
          'Global' => {
            'path' => 'test/',
            'page_index_format' => '%02d',
            'pages' => [ 'test.svg' ]
          }
        },
        {
          'Global' => {
            'path' => 'test/',
            'page_index_format' => '%02d',
            'pages' => [ 'test.svg' ],
            'files' => [ 'test/test.svg' ],
            'fileinfo_by_file' => {}
          }
        }
      ],
      [
        {
          'Global' => {
            'path' => 'test/',
            'page_index_format' => '%02d',
            'pages' => [ 'blank' ]
          }
        },
        {
          'Global' => {
            'path' => 'test/',
            'page_index_format' => '%02d',
            'pages' => [ 'blank' ],
            'files' => [ 'test/blank' ],
            'fileinfo_by_file' => { 'test/blank' => { 'file' => 'blank' } }
          }
        }
      ],
      [
        {
          'Global' => {
            'path' => 'test/',
            'page_index_format' => '%02d',
            'pages' => [ {} ]
          }
        },
        {
          'Global' => {
            'path' => 'test/',
            'page_index_format' => '%02d',
            'pages' => [ {} ],
            'files' => [ {} ],
            'fileinfo_by_file' => {}
          }
        }
      ],
      [
        {
          'Global' => {
            'path' => 'test/',
            'page_index_format' => '%02d',
            'pages' => [ { 'file' => 'test', 'param' => 'test2' } ]
          }
        },
        {
          'Global' => {
            'path' => 'test/',
            'page_index_format' => '%02d',
            'pages' => [ { 'file' => 'test', 'param' => 'test2' } ],
            'files' => [ 'test/test' ],
            'fileinfo_by_file' => { 'test/test' => { 'file' => 'test', 'param' => 'test2' } }
          }
        }
      ],
      [
        {
          'Global' => {
            'path' => 'test/',
            'page_index_format' => '%02d',
            'pages' => [ { 'file' => [ 'test', 'test2' ], 'param' => 'test2' } ]
          }
        },
        {
          'Global' => {
            'path' => 'test/',
            'page_index_format' => '%02d',
            'pages' => [ { 'file' => [ 'test', 'test2' ], 'param' => 'test2' } ],
            'files' => [ [ 'test/test', 'test/test2' ] ],
            'fileinfo_by_file' => { 'test/test,test/test2' => { 'file' => [ 'test', 'test2' ], 'param' => 'test2' } }
          }
        }
      ],
    ].each do |yaml, expected_result, expectations, files|
      @config_loader.expects(:load_yaml).with('file').returns(yaml)

      if expectations
        expectations.each do |expectation|
          e = @config_loader.expects(expectation[:expects])
          if expectation[:with]
            e.with(expectation[:with])
          end
          if expectation[:returns]
            e.returns(expectation[:returns])
          end
        end
      end

      FakeFS do
        if files
          FileUtils.touch files
        end

        assert_equal expected_result, @config_loader.load('file')
      end
    end
  end

  def test_load_yaml
    FakeFS do
      File.open('test', 'w') do |fh|
        fh.puts("- one\n- two\n- three")
      end

      assert_equal %w(one two three), @config_loader.load_yaml('test')
    end
  end

  def test_count_pattern
    FakeFS do
      FileUtils.touch [ 'test', 'test2', 'test3' ]
      assert_equal '%01d', @config_loader.count_pattern('*')
    end
  end
end
