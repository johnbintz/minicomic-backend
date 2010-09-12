require File.dirname(__FILE__) + '/Filter.rb'

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
