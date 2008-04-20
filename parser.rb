require "rubygems"
require 'tidy'
require "iconv"
require "date"

Tidy.path = '/usr/lib/libtidy.dylib'

def dump_error(error)
  puts error = iso_timestamp + " -- #{@year}/#{@id}: " + error
  open("error_log.txt", "a") { |log| log.puts(error)}
end

def convert_to_utf8(input)
  input_encoding = "windows-1250"
  output_encoding = "utf-8"
  begin    
    converted = Iconv.new(output_encoding, input_encoding).iconv(input)  
  rescue Iconv::IllegalSequence => e
    puts e.message
    dump_error("problem s konverzijom u UTF-8")
  end
end

def tidy_html(input)
  xml = Tidy.open(:show_warnings=>true, :wrap=>9999, :output_xml=>true, :char_encoding=>"utf8", :word_2000=>true) do |tidy|
    xml = tidy.clean(input)
    # puts tidy.errors
    # puts tidy.diagnostics
  end
end

def conform_to_tei(input)
  tei = input
  tei.gsub!("&nbsp;", "")
  tei.gsub!(/<(\w+)\s+[^>]*>/, '<\1>') # makni sve atribute iz tagova
  tei.gsub!(/<(table|style)>.*?<\/(table|style)>/m, '') # makni tag i njegov sadržaj 
  tei.gsub!(/<\/?(div|su[bp]|html|head|u|span|font|[uo]l|a)>/, '') # makni ali ostavi sadržaj
  tei.gsub!(/<(\/?)(h\d|center|li|pre)>/, '<\1p>') # zamijeni s paragrafima
  tei.gsub!("<br>", "<lb/>")
  tei.gsub!("<b>", '<hi rend="bold">')
  tei.gsub!("<i>", '<hi rend="italic">')
  tei.gsub!(/<\/[bi]>/, "</hi>")
  tei.gsub!(/<(img|meta|link)>/, '')
  tei.gsub!(/<p>\s*?<\/p>/, "") # makni prazne paragrafe
  tei.gsub!("…", "...")
  tei.gsub!("\302\255", "") # čudan znak koji ne postoji?!
  tei.gsub!(/<!--.*?-->/m, "") # makni HTML komentare
  tei.gsub!(/\n(\n)+/, "\n") # makni sve newlineove osim prvog
  tei.squeeze!(" ")
  
  # izvuci datum i naziv
  begin
    date_and_title = tei.scan(%r{<title>.*?(\d{1,2}\.\d{1,2}\.\d{4})\.?([^>]*)</title>}m).flatten
    @date = date_and_title[0] + "."
    @title = date_and_title[1].strip
  rescue NoMethodError => e
    @date = "___DATUM_NEPOZNAT___"
    @title = "___NAZIV_NEPOZNAT___"
    dump_error("naziv nepoznat")
  end
  
  # sad makni i sam title
  tei.gsub!(/<title>.*?<\/title>/m, '')
  tei.strip!
  
  # izvuci autora
  begin
    author_scan = tei.scan(%r{<body>\s*?<p>(.*?)</p>}m).flatten
    @author = author_scan[0]
    raise NoMethodError if @author =~ /\d/ # provjeri da nije broj
    @author.gsub!(/<.+?\/?>/m, "") # ne želimo tagove...
    @author.gsub!("\n", ' ') # ...niti newlineove
    @author.gsub!("DrŽ", "Drž") # KLUDGE: ne znam zašto se ovo dešava
    @author.strip!
  rescue NoMethodError => e
    @author = "___AUTOR_NEPOZNAT___"
    dump_error("autor nepoznat")
  end
  
  # makni ID; ako je autor nepoznat (vjerojatno se radi o ispravku),
  # prvi p child bodyja će biti ID, u svim ostalim slučajevima je drugi
  if @author == "___AUTOR_NEPOZNAT___"
    tei.gsub!(/(<body>)\s*?<p>.*?<\/p>/m, '\1')
  else
    tei.gsub!(/(<body>\s*?<p>.*?<\/p>)\s*?<p>.*?<\/p>/m, '\1')
  end
  
  return tei, @date, @title, @author
end

public
def to_ascii
  self.gsub!(/š/, "s")
  self.gsub!(/Š/, "S")
  self.gsub!(/đ/, "dj")
  self.gsub!(/Đ/, "Dj")
  self.gsub!(/Dj([A-Z])/, 'DJ\1')
  self.gsub!(/ž/, "z")
  self.gsub!(/Ž/, "Z")
  self.gsub!(/č/, "c")
  self.gsub!(/Č/, "C")
  self.gsub!(/ć/, "c")
  self.gsub!(/Ć/, "C")
  self.gsub!(/[<>|\\*"]/, "")
  self.gsub!(/[:?]/, " ")
  self.gsub!(/\//, "-")
  self
end

def truncate
  self[0..127]
end

def iso_timestamp
  timestamp = DateTime.now
  timestamp.to_s
end