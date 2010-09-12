require 'minicomic-backend/output_filter'
require 'minicomic-backend/print_handling'

#
# Convert a bitmap to a single page print for proofing
#
class TempBitmapToPrint < OutputFilter
  include PrintHandling

  def build(input, output)
    build_for_print(input, "| pbm:- | sam2p -c:lzw -m:dpi:#{calculate_dpi} - PDF:\"#{output}\"")
  end

  def calculate_dpi
    (72.0 * (72.0 / @config['dpi'].to_f))
  end
end
