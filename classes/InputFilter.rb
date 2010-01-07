require File.dirname(__FILE__) + '/Filter.rb'

class InputFilter < Filter
  attr_accessor :output_filename

  def initialize
    super
    @output_filename = "tmp.png"
  end
end
