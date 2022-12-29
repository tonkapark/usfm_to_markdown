
# Process USFM File(s) to Obsidian Markdown
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


def process_book(filename, output_dir: './obsidian')
  # Read One Book At A Time
  puts "Processing #{filename} ..."

  # Read the USFM text from the file
  usfm_text = File.read(filename)

  # Initialize the book hash
  @book = {}
  @book[:chapters] = []
  @chapter = {}
  @verse = {}
  @mode = :none


  # remove references and footnotes from the text
  usfm_text = usfm_text.gsub(/\\f.*\\f\*/,'')
  
  # cleanup bad poetry markers
  usfm_text = usfm_text.gsub(/(\\c \d+\r\n)\\q1\s/,'\1\\v 1 ')

  # remove poetry markers, keep verse lines together
  usfm_text = usfm_text.gsub(/\r\n\\q\d /,'')
  
 # puts usfm_text.inspect


  # Get Book ID
  if idx = usfm_text.match(/\\id\s([A-Z]{3})/)
    @book[:abbrev] = idx[1].to_s.strip
  end

  # Get Book Title
  if titles = usfm_text.match(/\\h\s(.*)\s/)
    title = titles[1].to_s.strip
    @book[:title] = title
    @book[:slug] = title.gsub(' ', '').downcase
  end

  # Split the USFM text into lines
  lines = usfm_text.split("\n")
  
  # Iterate over each line of the USFM text
  lines.each do |line|
    # Check if the line has a USFM marker
    if line[/^\\\w+/]
      # Default Extraction of the marker and the text following the marker
      marker, text = line.split(' ', 2)

      # Handle different markers differently
      case line[/^\\\w+/] 
      when '\\c'
        # Chapter number
        if @mode == :verse
          @chapter[:verses] << @verse
          @book[:chapters] << @chapter
          @chapter = {}
          @verse = {}
        end
        @mode = :chapter
        @chapter[:num] = text.to_i
        @chapter[:verses] = []
      when '\\v' # Verse line
        if @mode == :verse   
          @chapter[:verses] << @verse
          @verse = {}
        end
        @mode = :verse
        # remove footnotes and references - TODO: handle these in the future
        line = line.gsub(/\\f.*\\f\*/,'')

        verse_regex = /\\v (\d+)\s(.*)/
        
        if match = line[verse_regex].match(verse_regex)
          num = match[1]
          text = match[2]
        end
        @verse[:num] = num.to_i
        @verse[:text] = text
      when '\\q1' || '\\q2' # Poetry line
        @verse[:text] += "#{text}"
      end
    end
  end

  # add last verse and chapter
  @chapter[:verses] << @verse
  @book[:chapters] << @chapter

  #return @book
  write_book(@book)
end

def write_book(book, output_dir: './obsidian')
  # Write the book to a file
  
  output_path = Pathname.new(output_dir).join("#{book[:slug]}.md")
  File.open(output_path, 'w') do |file|
    book[:chapters].each do |chapter|
      file.write("# #{book[:title]} #{chapter[:num]}\n\n")
      chapter[:verses].each do |verse|
        file.write("#{verse[:num]} #{verse[:text]} ^v#{chapter[:num]}-#{verse[:num]}\n\n")
      end
    end
  end
end


#process_book('./usfm/19PSABSB.usfm')
process_bible()