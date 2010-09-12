require 'minicomic-backend/scheduler'

class ConfigLoader
  def load(file)
    config = load_yaml(file)

    if !config['Global']
      return false
    end

    global = config['Global']

    if !global['path']
      return false
    end

    if !global['page_index_format']
      global['page_index_format'] = count_pattern(global['path'])
    end

    files = []
    fileinfo_by_file = {}

    if global['pages']
      files = global['pages'].collect do |f|
        result = nil
        case f.class.to_s
          when 'String'
            result = global['path'] + f
            if f == "blank"
              fileinfo_by_file[result] = { 'file' => f }
            end
          when 'Hash'
            if f['file']
              case f['file'].class.to_s
                when 'String'
                  result = global['path'] + f['file']
                  fileinfo_by_file[result] = f
                when 'Array'
                  result = f['file'].collect { |sub_f| global['path'] + sub_f }
                  fileinfo_by_file[result.join(",")] = f
              end
            else
              result = f
            end
        end
        result
      end
    else
      if global['match']
        re = Regexp.new(global['match'])

        files = Dir[global['path'] + '/*'].sort.collect do |filename|
          if matches = re.match(filename)
            filename
          end
        end.compact
      end
    end

    global['files'] = files
    global['fileinfo_by_file'] = fileinfo_by_file

    config['Global'] = global

    scheduler = Scheduler.instance
    config.each do |type, info|
      if type != "Global"
        if info['schedule']
          info['publish_dates'] = scheduler.schedule(info['schedule'], files.length)
        end
      end
    end

    config
  end

  def load_yaml(file)
    YAML::load(File.open(file, "r"))
  end

  def count_pattern(path)
    "%0#{Math.log10(Dir[path].length).ceil}d"
  end
end
