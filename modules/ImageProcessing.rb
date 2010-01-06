module ImageProcessing
  def setup_inkscape(target)
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

    if width && (width.to_i != 0)
      params << "-w #{width}"
    end
    if height && (height.to_i != 0)
      params << "-h #{height}"
    end

    [ params, inkscape_target ]
  end

  #
  # Build a PNG from an SVG file
  #
  def inkscape(input, target)
    params, inkscape_target = setup_inkscape(target)

    call_system("inkscape -e \"#{inkscape_target}\" -y 1.0 #{params.join(" ")} \"#{input}\"")

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
    call_system("convert " + (verbose ? "-verbose " : "" ) + [ command ].flatten.join(" "))
  end

  def call_system(command)
    Kernel.system(command)
  end
end
