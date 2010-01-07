#
# Code to help with pagination
#
module Pagination
  def paginate(files)
    if !files.instance_of? Array; raise "File list must be an array"; end
    if files.length == 0; raise "File list cannot be empty"; end
    if (files.length % 4) != 0; raise "File list must be divisible by 4"; end

    tmp_pdf_files = []
    sheet_faces = setup_sheet_faces(files)

    sheet_faces.each_index do |i|
      f = @config['target'] + "-#{i}.pdf"
      process_pagination(f, i, sheet_faces.length, *sheet_faces[i])
      tmp_pdf_files << f
    end

    system("pdfjoin #{tmp_pdf_files.collect { |f| "\"#{f}\"" }.join(" ")} --outfile \"#{@config['target']}\"")
  end

  def setup_sheet_faces(files)
    number_of_sheet_faces = (files.length / 4) * 2

    sheet_faces = []

    is_right = 1
    is_descending = 1
    sheet_face_index = 0

    files.each do |file|
      if !sheet_faces[sheet_face_index]; sheet_faces[sheet_face_index] = []; end

      sheet_faces[sheet_face_index][is_right] = file
      is_right = 1 - is_right

      sheet_face_index += is_descending

      if sheet_face_index == number_of_sheet_faces
        sheet_face_index -= 1
        is_descending = -1
      end
    end

    sheet_faces
  end
end
