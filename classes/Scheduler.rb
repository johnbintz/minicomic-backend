require 'singleton'

class Scheduler
  include Singleton

  WEEKLY = [ 7 ]
  DAILY  = [ 1 ]

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

  def ok_to_add(date, breaks)
    ok = true
    breaks.each do |i|
      if (i[:from] <= date) && (i[:to] >= date)
        ok = false
      end
    end
    ok
  end

  def schedule(parameters, to_produce)
    dates = []

    if parameters[:start]
      current = parameters[:start]

      breaks = parameters[:breaks] || []

      while dates.length < to_produce
        interval = parameters[:interval].shift

        case interval.class.to_s
          when 'String'
            current = skip_to_dow(current, interval)

            if ok_to_add(current, breaks)
              dates << current
            end

            current += 1
          when 'Fixnum'
            if ok_to_add(current, breaks)
              dates << current
            end

            current += interval
        end

        parameters[:interval] << interval
      end
    end

    dates
  end
end
