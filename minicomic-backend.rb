#!/usr/bin/ruby

require 'yaml'
require 'time'

Dir[File.dirname(__FILE__) + "/classes/*.rb"].each do |file|
  require file
end

class OutputFilter < Filter
  #
  # get the output filename for this filter
  #
  def filename(info)
    target = @config['target']
    info.each { |k,v| target = target.gsub("{#{k}}", v.to_s) }
    target
  end

  #
  # get the output targets for this filter
  #
  def targets(info); filename(info); end
end

module PrintHandling
  #
  # calculate the page size in PPI
  #
  def calculate_page_size
    if @config['dpi']
      if @config['page_size']
        case @config['page_size'].downcase
          when "letter", "letter_portrait"
            page_width = 8.5; page_height = 11
          when "letter_landscape"
            page_width = 11; page_height = 8.5
          when "half_letter_landscape"
            page_width = 5.5; page_height = 8.5
        end
      else
        page_width = @config['page_width_inches']
        page_height = @config['page_height_inches']
      end

      page_width  *= @config['dpi']
      page_height *= @config['dpi']
    else
      page_width = @config['page_width']
      page_height = @config['page_height']
    end

    [ page_width, page_height ]
  end

  #
  # align the provided image on a white page
  #
  def build_for_print(input, output, side = "none")
    page_width, page_height = calculate_page_size
    command = [
      "-density #{config['dpi']}",
      "-size #{page_width.to_i}x#{page_height.to_i}",
      "xc:white"
    ]

    case side
      when "none"
        command << "-gravity Center"
      when "left"
        command << "-gravity East"
      when "right"
        command << "-gravity West"
    end

    command << "-draw 'image Over 0,0 0,0 \"#{input}\"'"

    if output[0,1] == "|"
      command << output[1..-1]
    else
      command << "\"#{output}\""
    end

    convert(command)
  end
end

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
    filename = Dir.pwd + '/' + OutputFilename
    inkscape(input, filename)
    @cleanup << filename

    if @config['spread']
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
        @cleanup << target
      end

      return targets
    end

    return filename
  end

  #
  # combine multiple input files onto a single page-sized canvas.
  # images are added left-to-right and top-to-bottom starting from the top-left of the page.
  # leave a grid square blank by passing the filename "/blank".
  #
  def multiple(files)
    if @config['spread']; raise "Spreads and grids combined do not make sense"; end

    width, height = @config['grid'].split("x").collect { |f| f.to_f }
    joined_files = []

    page_width, page_height = calculate_page_size

    grid_width = page_width / width
    grid_height = page_height / height

    0.upto(files.length - 1) do |i|
      x = i % width
      y = (i / width).floor

      if files[i].split('/').last != "blank"
        tmp_svg_output = OutputFilename + "-#{i}.png"
        inkscape(Dir.pwd + '/' + files[i], tmp_svg_output)

        joined_files << [ tmp_svg_output, x, y ]
        @cleanup << tmp_svg_output
      end
    end

    command = [
      "-size #{page_width}x#{page_height}",
      "xc:white"
    ]

    joined_files.each do |file, x, y|
      image_width, image_height = get_dimensions(file)

      x_offset = (grid_width - image_width) / 2
      y_offset = (grid_height - image_height) / 2

      command << "\"#{file}\" -geometry +#{x * grid_width + x_offset}+#{y * grid_height + y_offset} -composite"
    end

    command << OutputFilename

    convert(command)

    @cleanup << OutputFilename
    OutputFilename
  end
end

#
# Process an input file for the Web
#
class TempBitmapToWeb < OutputFilter
  def build(input, output)
    quality = @config['quality'] ? @config['quality'] : 80
    convert("\"#{input}\" -quality #{quality} \"#{output}\"")
  end

  def filename(info)
    if !@config['start_date']; raise "Must define a start date!"; end
    if !@config['period']; raise "Must define a period!"; end

    index = info['index'].to_i
    if index == 0 && @config['announce_date']
      comic_date = @config['announce_date']
    else
      day_of_week = 0
      weeks_from_start = 0

      case @config['period']
        when "daily"
          day_of_week = index % 5
          weeks_from_start = (index / 5).floor
        when "weekly"
          weeks_from_start = index
      end

      if @config['delay_at_index'] && @config['delay_length_weeks']
        if index >= @config['delay_at_index']
          weeks_from_start += @config['delay_length_weeks']
        end
      end

      comic_date = Time.parse(@config['start_date']) + ((((day_of_week + weeks_from_start * 7) * 24) + 6) * 60 * 60)
    end

    info['date'] = comic_date.strftime("%Y-%m-%d")
    super(info)
  end
end

#
# Code to help with pagination
#
module Pagination
  def paginate(files)
    if !files.instance_of? Array; raise "File list must be an array"; end
    if files.length == 0; raise "File list cannot be empty"; end
    if (files.length % 4) != 0; raise "File list must be divisible by 4"; end

    number_of_sheet_faces = (files.length / 4) * 2

    sheet_faces = []

    is_right = 1
    is_descending = 1
    sheet_face_index = 0

    files.each do |file|
      if !sheet_faces[sheet_face_index]; sheet_faces[sheet_face_index] = []; end

      sheet_faces[sheet_face_index][is_right] = file
      is_right = 1 - is_right

      sheet_face_index += is_descending

      if sheet_face_index == number_of_sheet_faces
        sheet_face_index -= 1
        is_descending = -1
      end
    end

    tmp_pdf_files = []
    0.upto(sheet_faces.length - 1) do |i|
      f = @config['target'] + "-#{i}.pdf"
      process_pagination(f, i, sheet_faces.length, *sheet_faces[i])
      tmp_pdf_files << f
    end

    system("pdfjoin #{tmp_pdf_files.collect { |f| "\"#{f}\"" }.join(" ")} --outfile \"#{@config['target']}\"")
  end
end

#
# Convert a bitmap to a single page print for proofing
#
class TempBitmapToPrint < OutputFilter
  include PrintHandling
  def build(input, output)
    build_for_print(input, "| pbm:- | sam2p -c:lzw -m:dpi:#{(72.0 * (72.0 / @config['dpi'].to_f))} - PDF:\"#{output}\"")
  end
end

#
# Convert bitmap files to a paginated print-ready file
#
class TempBitmapToPaginatedPrint < OutputFilter
  include PrintHandling, Pagination
  def build(input, output, side = "none")
    build_for_print(input, output, side)
  end

  def targets(info)
    (@config['spread'] == true) ? [ filename(info) + "-left.png", filename(info) + "-right.png" ] : filename(info)
  end

  def process_pagination(output, face, total_faces, left, right)
    page_width, page_height = calculate_page_size

    commands = [
        "-size #{page_width * 2}x#{page_height}",
        "xc:white"
    ]

    left_creep = 0
    right_creep = 0
    if @config['page_thickness']
      max_creep = (total_faces / 2)

      left_creep = ((max_creep - (face - max_creep).abs) * @config['page_thickness'].to_f * @config['dpi'].to_i).floor
      right_creep = ((max_creep - (total_faces - face - max_creep).abs) * @config['page_thickness'].to_f  * @config['dpi'].to_i).floor
    end

    if left
      commands << "\"#{left}\" -geometry +#{left_creep.to_i}+0 -composite"
    end
    if right
      commands << "\"#{right}\" -geometry +#{(page_width + right_creep).to_i}+0 -composite"
    end
    commands << "-colorspace RGB -depth 8 pnm:- | sam2p -c:lzw -m:dpi:#{(72.0 * (72.0 / @config['dpi'].to_f))} - PDF:\"#{output}\""

    convert(commands)
  end
end

any_rebuilt = false
any_rsync = false

if !ARGV[0]
  puts "Usage: #{File.basename(__FILE__)} <path to YAML file>"
  exit 0
end

if !File.exists?(ARGV[0])
  puts "#{ARGV[0]} doesn't exist!"
  exit 1
end

config = YAML::load(File.open(ARGV[0], "r"))
global = config['Global']

if !global['path']; exit 1; end

page_index_format = global['page_index_format'] ? global['page_index_format'] : "%0#{Math.log10(Dir[global['path']].length).ceil}d"

page_index = 1
fileinfo_by_file = {}

if global['pages']
  re = nil

  files = global['pages'].collect do |f|
    result = nil
    case f.class.to_s
      when 'String'
        result = global['path'] + f
        if f == "blank"
          fileinfo_by_file[result] = { 'file' => f }
        end
      when 'Hash'
        if f['file']
          case f['file'].class.to_s
            when 'String'
              result = global['path'] + f['file']
              fileinfo_by_file[result] = f
            when 'Array'
              result = f['file'].collect { |sub_f| global['path'] + sub_f }
              fileinfo_by_file[result.join(",")] = f
          end
        else
          result = f
        end
    end
    result
  end
else
  re = Regexp.new(global['match'])

  files = Dir[global['path']].sort.collect do |filename|
    if matches = re.match(filename)
      filename
    end
  end
end

paginated_source_files = {}
rsync_files_by_target = {}

files.each do |filename|
  ok = true; matches = nil; fileinfo = {}

  if filename.instance_of? Hash
    if filename['blank']
      ok = false
      config.each do |type, info|
        if info['is_paginated']
          if !paginated_source_files[type]; paginated_source_files[type] = []; end
          paginated_source_files[type] << nil
        end
      end
      page_index += 1
    else
      fileinfo = filename
      filename = fileinfo['file']
    end
  else
    if re; ok = matches = re.match(filename); end
  end

  if ok
    filename_display = (filename.instance_of? Array) ? filename.join(", ") : filename

    puts "Examining #{filename_display}..."

    filename_parts = {
      'page_index' => sprintf(page_index_format, page_index)
    }

    if matches
      all, index, title = matches.to_a
    else
      index = page_index - 1
      title = ""
    end

    if global['title']; title = global['title'].gsub("{index}", index).gsub("{title}", title); end
    filename_parts['index'] = index
    filename_parts['title'] = title

    config.each do |type, info|
      if type != "Global"
        input = nil; output = nil

        fileinfo_key = (filename.instance_of? Array) ? filename.join(",") : filename

        file_fileinfo = (fileinfo_by_file[fileinfo_key]) ? fileinfo_by_file[fileinfo_key] : {}

        extension = File.extname((filename.instance_of? Array) ? filename[0] : filename).downcase

        case extension
          when ".svg"
            case File.extname(config[type]['target']).downcase
              when ".jpg", ".jpeg", ".png", ".gif"
                input = SVGToTempBitmap
                output = TempBitmapToWeb
              when ".pdf"
                input = SVGToTempBitmap
                output = (info['is_paginated']) ? TempBitmapToPaginatedPrint : TempBitmapToPrint
            end
        end

        if !input;  raise "No input handler for #{extension} defined"; end
        if !output; raise "No output handler for #{File.extname(config[type]['target']).downcase} defined"; end

        input_obj = input.instance
        input_obj.config = info.dup.merge(fileinfo).merge(file_fileinfo)

        output_obj = output.instance
        output_obj.config = info.dup.merge(fileinfo).merge(file_fileinfo)

        if info['is_paginated']
          output_obj.config['target'] += "-{page_index}.png"
        end

        targets = output_obj.targets(filename_parts)

        rebuild = false

        [ targets ].flatten.each do |t|
          if !File.exists?(t)
            rebuild = true
          else
            [ filename ].flatten.each do |f|
              if File.basename(f) != "blank"
                if File.mtime(f) > File.mtime(t)
                  rebuild = true
                end
              end
            end
          end
        end

        if rebuild
          any_rebuilt = true

          puts "Rebuilding #{filename_display} (#{type})..."
          puts "  Using #{filename} as a source"
          puts "  and writing to #{targets.inspect}"

          tmp_files = input_obj.build(filename)

          output_files = []
          case tmp_files.class.to_s
            when "String"
              output_obj.build(tmp_files, targets)
              output_files << targets
            when "Array"
              [0,1].each do |i|
                output_obj.build(tmp_files[i], targets[i], (i == 0) ? "left" : "right")
                output_files << targets[i]
              end
          end

          input_obj.cleanup
        end
        if info['is_paginated']
          if !paginated_source_files[type]; paginated_source_files[type] = []; end
          paginated_source_files[type] << targets
        end
        if info['rsync']
          if !rsync_files_by_target[info['rsync']]; rsync_files_by_target[info['rsync']] = []; end
          rsync_files_by_target[info['rsync']] << targets
        end
      end
    end

    page_index += 1
  end
end

config.each do |type, info|
  if info['is_paginated']
    output = TempBitmapToPaginatedPrint

    output_obj = output.instance
    output_obj.config = info.dup

    output_obj.paginate(paginated_source_files[type].flatten)
  end

  if info['rsync']
    system("echo '#{rsync_files_by_target[info['rsync']].join("\n")}' | rsync -vru --files-from=- . #{info['rsync']}")
  end
end

if global['use_git']
  system("git add .")
  system("git commit -a")
end
