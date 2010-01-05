require 'singleton'

class Scheduler
  include Singleton

  WEEKLY = [ 7 ]

  def skip_to_dow(date, dow)
    if dow.is_a? String
      dow = Date::DAYNAMES.collect { |d| d.downcase }.index(dow.downcase)
    end

    if dow.is_a? Fixnum
      while date.wday != dow
        date += 1
      end
    end
    date
  end

  def schedule(parameters, to_produce)
    dates = []

    if parameters[:start]
      current = parameters[:start]

      1.upto(to_produce) do |i|
        interval = parameters[:interval].shift

        case interval.class.to_s
          when 'String'
            current = skip_to_dow(current, interval)

            dates << current

            current += 1
          when 'Fixnum'
            dates << current

            current += interval
        end

        parameters[:interval] << interval
      end
    end

    dates
  end
end
