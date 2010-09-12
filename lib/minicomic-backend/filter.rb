require 'fileutils'

class Filter
  @config = {}
  @cleanup = []

  attr_accessor :config, :cleanup

  def initialize
    @config = {}
    @cleanup = []
  end

  def cleanup
    @cleanup.each do |f|
      FileUtils.rm(f) if File.file?(f)
    end
  end

  def recalc_pixels
    if @config['print']
      if !@config['dpi']; raise "DPI not defined"; end
      if (@config['dpi'].to_i.to_s) != @config['dpi'].to_s; raise "DPI not integer"; end
      if @config['width_inches'] && (@config['width_inches'].to_f != 0)
        @config['width'] = (@config['width_inches'].to_f * @config['dpi'].to_f).to_i
      else
        @config.delete('width')
      end
      if @config['height_inches'] && (@config['height_inches'].to_f != 0)
        @config['height'] = (@config['height_inches'].to_f * @config['dpi'].to_f).to_i
      else
        @config.delete('height')
      end

      if (!@config['width'] && !@config['height'])
        raise "No dimensions defined!"
      end
    end
  end

  #
  # Set the config
  #
  def config=(c)
    @config = c

    recalc_pixels
  end

  #
  # Get the dimensions of a file
  #
  def get_dimensions(input)
    dimensions = nil
    IO.popen("identify -format '%w,%h' \"#{input}\"") do |fh|
      dimensions = fh.readlines.first.split(",").collect { |d| d.to_i }
    end
    dimensions
  end
end
