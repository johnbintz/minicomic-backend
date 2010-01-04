require 'singleton'

class Scheduler
  include Singleton

  WEEKLY = [ 7 ]

  def schedule(parameters, to_produce)
    dates = []

    if parameters[:start]
      current = parameters[:start]

      1.upto(to_produce) do |i|
        interval = parameters[:interval].shift

        case interval.class.to_s
          when 'Symbol'

          when 'Fixnum'
        end

        dates << current

        current += interval
        parameters[:interval] << interval
      end
    end

    dates
  end
end
