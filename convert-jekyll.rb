# convert a usfm file or list of files into Jekyll Markdown HTML format
require 'pathname'

  def process_bible(dir_path: './usfm')
    dir = Dir.open(dir_path)

    # Loop over each entry in the directory
    dir.each_entry do |entry|
      # Get the full path to the entry
      entry_path = Pathname.new(dir_path).join(entry)
      
      # Skip the entry if it is not a file
      next unless entry_path.file?
      book = process_book(entry_path)  
    end

    # Close the directory
    dir.close
  end

  def process_book(filename, output_dir: './')
    # Read One Book At A Time
    puts "Processing #{filename} ..."

    # Read the USFM text from the file
    usfm_text = File.read(filename)
    # Split the USFM text into lines
    lines = usfm_text.split("\n")

    # Initialize an empty array to store the HTML output
    html_output = []
    @book_title = ''

    # Iterate over each line of the USFM text
    lines.each do |line|
      # Check if the line has a USFM marker
      if line[/^\\\w+/]
        # Default Extraction of the marker and the text following the marker
        marker, text = line.split(' ', 2)

        # Handle different markers differently
        case line[/^\\\w+/]    
        when '\\h'
          @book_title = text.to_s.strip
        when '\\c'
          # Chapter number
          chapter_number = text.to_i
          # For the '\c' marker, add a heading element
          html_output << "<h2>#{chapter_number}</h2>"
        when '\\v'
          # remove footnotes and references - TODO: handle these in the future
          line = line.gsub(/\\f.*\\f\*/,'')

          verse_regex = /\\v (\d+)\s(.*)/
          
          if match = line[verse_regex].match(verse_regex)
            num = match[1]
            text = match[2]

            # For the '\v' marker, add a paragraph element
            html_output << "<span class='v'><span class='vn'>#{num}</span> #{text}</span>"
          end
        end
      end
    end

    # Join the HTML output into a single string
    meta = [] 
    meta << "---"
    meta << "layout: page"
    meta << "title: #{@book_title}"
    meta << "permalink: /#{@book_title.gsub(' ','').downcase}"
    meta << "---"

    html = meta.concat(html_output).join("\n")

    output_file = "./jekyll/#{@book_title.gsub(' ','').downcase.to_s}.html" 
    puts "Output: #{output_file}"
    # Write the HTML to a file
    File.write(output_file, html)

  end



# puts "Processing ..."
#process_book('./usfm/50EPHBSB.usfm')
process_bible


