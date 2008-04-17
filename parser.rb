require "rubygems"
require 'tidy'
require "iconv"


Tidy.path = 'tidy/libtidy.dylib'

# simulacija gettera
test_sources = ["input_test_2000.htm", "input_test_2004.htm", "input_test_2005.htm", "input_test_2008.htm"]

def convert_to_utf8(input)
  input_encoding = "windows-1250"
  output_encoding = "utf-8"
  converted = Iconv.new(output_encoding, input_encoding).iconv(input)  
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
  tei.gsub!(/<(table|style)>.*?<\/(table|style)>/m, '') # makni sve tablice i njihov sadržaj 
  tei.gsub!(/<\/?(div|sup|html|head|u)>/, '') # makni div, sup, html, head, u ali ostavi sadržaj
  tei.gsub!(/<(\/?)(h\d|center|font)>/, '<\1p>') # headinge i center zamijeni s paragrafima
  tei.gsub!("<br>", "<lb/>")
  tei.gsub!("<b>", '<hi rend="bold">')
  tei.gsub!("<i>", '<hi rend="italic">')
  tei.gsub!(/<\/[bi]>/, "</hi>")
  tei.gsub!(/<(img|meta|link)>/, '')
  tei.gsub!(/<p>\s*?<\/p>/, "") # makni prazne paragrafe
  tei.gsub!("…", "...")
  tei.gsub!("\302\255", "") # čudan znak koji ne postoji?!
  tei.gsub!(/(<body>\s*?<p>.*?<\/p>)\s*?<p>.*?<\/p>/m, '\1') # makni ID
  tei.gsub!(/\n(\n)+/, "\n") # makni sve newlineove osim prvog
  tei.squeeze!(" ")
  
  # izvuci datum i naziv
  date_and_title = tei.scan(%r{<title>\s*?\d+\s+?(\d{1,2}\.\d{1,2}\.\d{4})\.?([^>]*)</title>}).flatten
  @date = date_and_title[0] + "."
  @title = date_and_title[1].strip
  
  # sad makni i sam title
  tei.gsub!(/<title>.*?<\/title>/m, '')
  tei.strip!
  
  # izvuci autora
  author_scan = tei.scan(%r{<body>\s*?<p>(.*?)</p>}).flatten
  @author = author_scan[0].strip
  
  return tei, @date, @title, @author
end

public
def to_ascii # http://www.jroller.com/obie/entry/fix_that_tranny_add_to
  converter = Iconv.new('ASCII//IGNORE//TRANSLIT', 'UTF-8') 
  converter.iconv(self).unpack('U*').select{ |cp| cp < 127 }.pack('U*')
end

test_sources.each do |source|
  loaded_html = open("#{source}") { |line| line.read }
  html_utf8 = convert_to_utf8(loaded_html)
  xml = tidy_html(html_utf8)
  tei_xml = conform_to_tei(xml)[0]
  open("output_test/#{@title.to_ascii}.xml", "w") { |line| line.puts tei_xml }
  puts @title
  puts @date
  puts @author
  puts
end
