require File.dirname(__FILE__) + '/InputFilter.rb'

class SVGToTempBitmap < InputFilter
  include PrintHandling

  #
  # select which build method to use based on the number of provided images.
  #
  def build(input)
    (input.instance_of? Array) ? multiple(input) : single(input)
  end

  #
  # process a single input file, possibly splitting it into two output files if it's a spread
  #
  def single(input)
    filename = Dir.pwd + '/' + @output_filename
    inkscape(input, filename)
    @cleanup << filename

    if @config['spread']
      targets = build_spread(filename)
      @cleanup.concat targets
      return targets
    end

    filename
  end

  def build_spread(filename)
    width, height = get_dimensions(filename)
    targets = []

    [ [ "left", 0 ], [ "right", width / 2 ] ].each do |side, offset|
      target = filename + "-#{side}.png"
      command = [
        "\"#{filename}\"",
        "-gravity Northwest",
        "-crop #{width/2}x#{height}+#{offset}+0",
        "+repage",
        "\"#{target}\""
      ]

      convert(command)

      targets << target
    end

    targets
  end

  #
  # combine multiple input files onto a single page-sized canvas.
  # images are added left-to-right and top-to-bottom starting from the top-left of the page.
  # leave a grid square blank by passing the filename "/blank".
  #
  def multiple(files)
    if @config['spread']; raise "Spreads and grids combined do not make sense"; end

    width, height = @config['grid'].split("x").collect { |f| f.to_f }

    page_width, page_height = calculate_page_size

    grid_width = page_width / width
    grid_height = page_height / height

    joined_files = join_files(files, width)

    command = [
      "-size #{page_width}x#{page_height}",
      "xc:white"
    ]

    command.concat generate_joined_files_command(joined_files, grid_width, grid_height)

    command << "\"#{@output_filename}\""

    convert(command)

    @cleanup.concat joined_files.collect { |file, x, y| file }
    @cleanup << @output_filename

    @output_filename
  end

  def join_files(files, width)
    joined_files = []

    files.each_index do |i|
      x = i % width
      y = (i / width).floor

      if files[i].split('/').last != "blank"
        tmp_file = @output_filename + "-#{i}.png"
        inkscape(Dir.pwd + '/' + files[i], tmp_file)

        joined_files << [ tmp_file, x, y ]
      end
    end

    joined_files
  end

  def generate_joined_files_command(files, grid_width, grid_height)
    command = []

    files.each do |file, x, y|
      image_width, image_height = get_dimensions(file)

      x_offset = (grid_width - image_width) / 2
      y_offset = (grid_height - image_height) / 2

      command << "\"#{file}\" -geometry +#{x * grid_width + x_offset}+#{y * grid_height + y_offset} -composite"
    end

    command
  end
end
