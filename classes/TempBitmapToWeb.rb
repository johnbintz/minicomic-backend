require File.dirname(__FILE__) + '/OutputFilter.rb'
require File.dirname(__FILE__) + '/../modules/ImageProcessing.rb'

#
# Process an input file for the Web
#
class TempBitmapToWeb < OutputFilter
  include ImageProcessing

  def build(input, output)
    quality = @config['quality'] ? @config['quality'] : 80
    convert("\"#{input}\" -quality #{quality} \"#{output}\"")
  end

  def filename(info)
    info['date'] = @config['publish_dates'][info['index'].to_i - 1].strftime(@config['date_format'])
    super(info)
  end
end
