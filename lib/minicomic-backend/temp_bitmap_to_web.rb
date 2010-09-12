require 'minicomic-backend/output_filter'
require 'minicomic-backend/image_processing'
require 'fileutils'

#
# Process an input file for the Web
#
class TempBitmapToWeb < OutputFilter
  include ImageProcessing

  def build(input, output)
    FileUtils.mkdir_p(File.split(output).first)
    quality = @config['quality'] ? @config['quality'] : 80
    convert("\"#{input}\" -quality #{quality} \"#{output}\"")
  end

  def filename(info)
    info['date'] = @config['publish_dates'][info['index'].to_i - 1].strftime(@config['date_format'])
    info['subdir'] = ''
    if @config['subdirs']
      @config['subdirs'].each do |dir, subdir_info|
        if Range.new(subdir_info['from'].to_i, subdir_info['to'].to_i).include? info['index'].to_i
          info['subdir'] = dir + File::SEPARATOR
          break
        end
      end
    end

    super(info)
  end
end
