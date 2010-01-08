
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
