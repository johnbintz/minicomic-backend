require 'rubygems'
require 'test/unit'
require 'mocha'
require 'fakefs/safe'
require File.dirname(__FILE__) + '/../modules/ImageProcessing.rb'

class TestImageProcessing < Test::Unit::TestCase
  def setup
    @instance = Class.new do
      include ImageProcessing

      attr_accessor :config
    end.new
  end

  def test_setup_inkscape
    [
      [ {}, [], 'target' ],
      [ { 'width' => 'test' }, [], 'target' ],
      [ { 'width' => 200 }, ['-w 200'], 'target' ],
      [ { 'height' => 'test' }, [], 'target' ],
      [ { 'height' => 200 }, ['-h 200'], 'target' ],
      [ { 'rotate' => 0 }, [], 'target' ],
      [ { 'rotate' => 90 }, [], 'target-pre.png' ],
      [ { 'rotate' => 90, 'width' => 50, 'height' => 75 }, ['-w 75', '-h 50'], 'target-pre.png' ],
    ].each do |config, expected_params, expected_target|
      @instance.config = config

      params, inkscape_target = @instance.setup_inkscape('target')

      assert_equal expected_params, params
      assert_equal inkscape_target, expected_target
    end
  end

  def test_handle_inkscape_rotation
    @instance.config = { 'rotate' => 90 }
    @instance.expects(:convert).with(['"target-pre.png"', '-rotate 90', '"target"'])

    FakeFS do
      FileUtils.touch('target-pre.png')
      @instance.handle_inkscape_rotation('target-pre.png', 'target')

      assert !(File.exists? 'target-pre.png')
    end
  end

  def test_convert
    [ false, true ].each do |verbose|
      @instance.expects(:call_system).with('convert ' + (verbose ? '-verbose ' : '') + 'test')
      @instance.convert(['test'], verbose)
    end
  end

  def test_inkscape
    @instance.expects(:call_system).with('inkscape -e "new-target" -y 1.0 -w 200 "input"')
    @instance.expects(:handle_inkscape_rotation).with('new-target', 'target')
    @instance.expects(:setup_inkscape).returns([['-w 200'], 'new-target'])

    @instance.inkscape('input', 'target')
  end
end
