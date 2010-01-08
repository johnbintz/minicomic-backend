class FileProcessor
  attr_accessor :config, :paginated_source_files, :page_index

  def initialize(config)
    @page_index = 0
    @config = config
    @paginated_source_files = {}
  end


  def process
    rsync_files_by_target = {}

    files.each do |filename|
      ok, fileinfo, filename = verify_filename(filename)

      if ok
        filename_display = (filename.instance_of? Array) ? filename.join(", ") : filename

        puts "Examining #{filename_display}..."

        config.each do |type, info|
          if type != "Global"
            input = nil; output = nil

            fileinfo_key = (filename.instance_of? Array) ? filename.join(",") : filename

            file_fileinfo = (fileinfo_by_file[fileinfo_key]) ? fileinfo_by_file[fileinfo_key] : {}

            file_fileinfo = info.dup.merge(fileinfo).merge(file_fileinfo)

            input_obj, output_obj, targets = construct_filters_and_targets(filename, file_fileinfo, ok)

            rebuild = false

            [ targets ].flatten.each do |t|
              if !File.exists?(t)
                rebuild = true
              else
                [ filename ].flatten.each do |f|
                  if File.basename(f) != "blank"
                    if File.mtime(f) > File.mtime(t)
                      rebuild = true
                    end
                  end
                end
              end
            end

            if rebuild
              any_rebuilt = true

              puts "Rebuilding #{filename_display} (#{type})..."
              puts "  Using #{filename} as a source"
              puts "  and writing to #{targets.inspect}"

              tmp_files = input_obj.build(filename)

              output_files = []
              case tmp_files.class.to_s
                when "String"
                  output_obj.build(tmp_files, targets)
                  output_files << targets
                when "Array"
                  [0,1].each do |i|
                    output_obj.build(tmp_files[i], targets[i], (i == 0) ? "left" : "right")
                    output_files << targets[i]
                  end
              end

              input_obj.cleanup
            end
            if info['is_paginated']
              if !paginated_source_files[type]; paginated_source_files[type] = []; end
              paginated_source_files[type] << targets
            end
            if info['rsync']
              if !rsync_files_by_target[info['rsync']]; rsync_files_by_target[info['rsync']] = []; end
              rsync_files_by_target[info['rsync']] << targets
            end
          end
        end

        page_index += 1
      end
    end

    config.each do |type, info|
      if info['is_paginated']
        output = TempBitmapToPaginatedPrint

        output_obj = output.instance
        output_obj.config = info.dup

        output_obj.paginate(paginated_source_files[type].flatten)
      end

      if info['rsync']
        system("echo '#{rsync_files_by_target[info['rsync']].join("\n")}' | rsync -vru --files-from=- . #{info['rsync']}")
      end
    end
  end

  def verify_filename(filename)
    ok = true
    fileinfo = {}

    if filename.instance_of? Hash
      if filename['blank']
        ok = false
        @config.each do |type, info|
          if info['is_paginated']
            if !@paginated_source_files[type]
              @paginated_source_files[type] = []
            end
            @paginated_source_files[type] << nil
          end
        end
        @page_index += 1
      else
        if filename['file']
          fileinfo = filename
          filename = fileinfo['file']
        else
          ok = false
        end
      end
    else
      if @config['Global']
        if @config['Global']['match']
          ok = Regexp.new(@config['Global']['match']).match(filename)
        end
      end
    end

    [ ok, fileinfo, filename ]
  end

  def build_filename_parts(match_data)
    filename_parts = {
      'page_index' => sprintf(@config['Global']['page_index_format'], @page_index)
    }

    if match_data.is_a? MatchData
      all, index, title = match_data.to_a
    else
      index = @page_index - 1
      title = ""
    end

    if @config['Global']['title']
      title = @config['Global']['title'].gsub("{index}", index).gsub("{title}", title)
    end

    filename_parts['index'] = index.to_i
    filename_parts['title'] = title

    filename_parts
  end

  def construct_filters_and_targets(filename, info, match_data)
    extension = File.extname((filename.instance_of? Array) ? filename[0] : filename).downcase

    case extension
      when ".svg"
        case File.extname(info['target']).downcase
          when ".jpg", ".jpeg", ".png", ".gif"
            input = SVGToTempBitmap
            output = TempBitmapToWeb
          when ".pdf"
            input = SVGToTempBitmap
            output = (info['is_paginated']) ? TempBitmapToPaginatedPrint : TempBitmapToPrint
        end
    end

    if !input;  raise "No input handler for #{extension} defined"; end
    if !output; raise "No output handler for #{File.extname(info['target']).downcase} defined"; end

    input_obj = input.new
    input_obj.config = info

    output_obj = output.new
    output_obj.config = info

    if info['is_paginated']
      output_obj.config['target'] += "-{page_index}.png"
    end

    targets = output_obj.targets(build_filename_parts(match_data))

    [ input_obj, output_obj, targets ]
  end
end
