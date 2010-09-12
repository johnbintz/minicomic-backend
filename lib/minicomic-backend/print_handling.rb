module PrintHandling
  #
  # calculate the page size in PPI
  #
  def calculate_page_size
    ok = false

    if @config['dpi']
      if @config['page_size']
        case @config['page_size'].downcase
          when "letter", "letter_portrait"
            page_width = 8.5; page_height = 11; ok = true
          when "letter_landscape"
            page_width = 11; page_height = 8.5; ok = true
          when "half_letter_landscape"
            page_width = 5.5; page_height = 8.5; ok = true
        end
      else
        if @config['page_width_inches'] && @config['page_height_inches']
          page_width = @config['page_width_inches']
          page_height = @config['page_height_inches']
          ok = true
        end
      end

      if ok
        page_width  *= @config['dpi'].to_i
        page_height *= @config['dpi'].to_i
      end
    end

    if !ok
      page_width = @config['page_width']
      page_height = @config['page_height']
    end

    [ page_width, page_height ]
  end

  #
  # align the provided image on a white page
  #
  def build_for_print(input, output, side = "none")
    page_width, page_height = calculate_page_size
    command = [
      "-density #{@config['dpi']}",
      "-size #{page_width.to_i}x#{page_height.to_i}",
      "xc:white"
    ]

    case side
      when "none"
        command << "-gravity Center"
      when "left"
        command << "-gravity East"
      when "right"
        command << "-gravity West"
    end

    command << "-draw 'image Over 0,0 0,0 \"#{input}\"'"

    if output[0,1] == "|"
      command << output[1..-1]
    else
      command << "\"#{output}\""
    end

    convert(command)
  end
end
