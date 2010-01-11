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

  def ok_to_add(date, index, prior, breaks)
    ok = true
    breaks.each do |i|
      if i['from'] && i['to']
        if (i['from'] <= date) && (i['to'] >= date)
          ok = false
        end
      end

      if i['at_index'] && i['for_days'] && prior
        if i['at_index'] == index
          ok = (date > (prior + i['for_days']))
        end
      end
    end
    ok
  end

  def schedule(parameters, to_produce)
    dates = []

    if parameters['start']
      current = parameters['start']
      prior = nil

      breaks = parameters['breaks'] || []

      all_strings = true
      parameters['interval'].each do |i|
        if !i.is_a? String
          all_strings = false
          break
        end
      end

      if all_strings
        parameters['interval'].each_index do |i|
          interval = parameters['interval'].shift
          if current == skip_to_dow(current, interval)
            parameters['interval'].unshift(interval)
            break
          else
            parameters['interval'].push(interval)
          end
        end
      end

      index = 0
      while dates.length < to_produce
        interval = parameters['interval'].shift

        what_to_add = nil

        if interval.is_a? String
          current = skip_to_dow(current, interval)

          what_to_add = 1
        end

        if ok_to_add(current, index, prior, breaks)
          dates << current
          prior = current
          index += 1
        end

        if interval.is_a? Fixnum
          what_to_add = interval
        end

        current += what_to_add

        parameters['interval'] << interval
      end
    end

    dates
  end
end
