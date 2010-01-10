require File.dirname(__FILE__) + '/OutputFilter.rb'

#
# Process an input file for the Web
#
class TempBitmapToWeb < OutputFilter
  def build(input, output)
    quality = @config['quality'] ? @config['quality'] : 80
    convert("\"#{input}\" -quality #{quality} \"#{output}\"")
  end

  def filename(info)
    index = info['index'].to_i

    info['date'] = @config['publish_dates'][index].strftime(@config['date_format'])
    super(info)
  end
end
