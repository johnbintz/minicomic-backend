require File.dirname(__FILE__) + '/OutputFilter.rb'

#
# Process an input file for the Web
#
class TempBitmapToWeb < OutputFilter
  attr_accessor :schedule

  def initialize
    super
    @schedule = nil
  end

  def requires_schedule(schedule)
    @schedule = schedule
  end

  def build(input, output)
    quality = @config['quality'] ? @config['quality'] : 80
    convert("\"#{input}\" -quality #{quality} \"#{output}\"")
  end

  def filename(info)
    index = info['index'].to_i
    info['date'] = @schedule[index].strftime(@config['date_format'])
    super(info)
  end
end
