require 'singleton'

class Filter
  include Singleton
  @config = {}
  @cleanup = []

  attr_accessor :config, :cleanup
  
  def initialize
    @config = {}
    @cleanup = []
  end

  def cleanup
    @cleanup.each do |f| 
      if File.exists? f; File.unlink(f); end
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
  # Build a temporary PNG from an SVG file
  #
  def inkscape(input, target)
    params = []

    width = @config['width']
    height = @config['height']
    inkscape_target = target
    
    if @config['rotate']
      case @config['rotate']
        when 90, -90
          t = width; width = height; height = t
          inkscape_target = target + "-pre.png"
      end
    end

    if width && (width.to_i != 0); params << "-w #{width} "; end
    if height && (height.to_i != 0); params << "-h #{height} "; end
    
    system("inkscape -e \"#{inkscape_target}\" -y 1.0 #{params.join(" ")} \"#{input}\"")    
    
    if @config['rotate']
      command = [
        "\"#{inkscape_target}\"",
        "-rotate #{@config['rotate']}",
        "\"#{target}\""
      ]
      
      convert(command)
      File.unlink(inkscape_target)
    end
  end

  def convert(command, verbose = false)
    if verbose
      puts "convert " + (verbose ? "-verbose " : "" ) + [ command ].flatten.join(" ")
    end
    system("convert " + (verbose ? "-verbose " : "" ) + [ command ].flatten.join(" "))
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
