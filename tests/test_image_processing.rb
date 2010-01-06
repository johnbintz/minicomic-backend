require "test/unit"
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
end
