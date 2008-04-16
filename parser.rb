require "rubygems"
require 'tidy'
require "iconv"


Tidy.path = 'tidy/libtidy.dylib'
@html = open("input_test_2008.htm") { |line| line.read } # simulacija gettera

def convert_to_utf8(input)
  input_encoding = "windows-1250"
  output_encoding = "utf-8"
  converted = Iconv.new(output_encoding, input_encoding).iconv(input)  
end

def tidy_html(html)
  html_utf8 = convert_to_utf8(@html)
  xml = Tidy.open(:show_warnings=>true, :wrap=>9999, :output_xml=>true, :char_encoding=>"utf8", :word_2000=>true) do |tidy|
    xml = tidy.clean(html_utf8)
    # puts tidy.errors
    # puts tidy.diagnostics
  end
end

def conform_to_tei
  tei = tidy_html(@html)
  tei.gsub!("&nbsp;", "")
  tei.gsub!(/<(\w+)\s+[^>]*>/, '<\1>') # makni sve atribute iz tagova
  tei.gsub!(/<(table|style)>.*?<\/(table|style)>/m, '') # makni sve tablice i njihov sadržaj 
  tei.gsub!(/<\/?(div|sup)>/, '') # makni div-ove i sup-ove
  tei.gsub!(/<(\/?)(h\d|center|font)>/, '<\1p>') # headinge i center zamijeni s paragrafima
  tei.gsub!("<br>", "<lb/>")
  tei.gsub!("<b>", '<hi rend="bold">')
  tei.gsub!("<i>", '<hi rend="italic">')
  tei.gsub!(/<\/[bi]>/, "</hi>")
  tei.gsub!(/<img>|<meta>/, '')
  tei.gsub!(/<p>\s*?<\/p>/, "") # makni prazne paragrafe
  tei.gsub!("…", "...")
  tei.gsub!("\302\255", "") # čudan znak koji ne postoji?!
  tei.gsub!(/\n(\n)+/, "\n") # makni sve newlineove osim prvog
  tei.squeeze!(" ")
  tei.strip!
  
  date_and_title = tei.scan(%r{<title>\s*?\d+\s+?(\d{1,2}\.\d{1,2}\.\d{4})\.?([^>]*)</title>}).flatten
  date = date_and_title[0] + "."
  title = date_and_title[1].strip
  
  return tei, date, title
end

xml = conform_to_tei[0]
open("output_test.xml", "w") { |line| line.puts xml }
puts conform_to_tei[2]
puts conform_to_tei[1]
