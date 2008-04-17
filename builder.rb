require "getter"
require "parser"

# simulacije gettera
# uris_to_parse = ["input_test_2000.htm", "input_test_2001.htm", "input_test_2002.htm", "input_test_2003.htm", "input_test_2004.htm", \
#                 "input_test_2005.htm", "input_test_2006.htm", "input_test_2007.htm", "input_test_2008.htm"]
# uris_to_parse = deserialize(URIS_FILE)
# uris_to_parse = ["input_test_2007-i.htm"]
uris_to_parse = ["http://www.nn.hr/clanci/sluzbeno/2006/0873.htm"]

puts "Počinjem parsiranje\n"
uris_to_parse.each do |source|
  
  # prvo dobij ID i godinu (korisno za hvatanje grešaka)
  meta_info = source.scan(%r{http://www.nn.hr/clanci/sluzbeno/(\d{4})/(\d{4,}).html?}).flatten
  @year = meta_info[0]
  @id = meta_info[1]
  puts "------------------------------------------------------------------------"
  
  # učitavanje dokumenta
  begin
    loaded_html = open(source) { |line| line.read }
  rescue SocketError => e
    puts "\nNe mogu se spojiti na poslužitelj Narodnih novina.\n"
    break
  rescue OpenURI::HTTPError => e
    dump_error("#{@year}/#{@id}: traženi dokument ne postoji\n")
    next
  end
  
  # konverzija i čišćenje
  html_utf8 = convert_to_utf8(loaded_html)
  xml = tidy_html(html_utf8) 
  tei_xml = conform_to_tei(xml)[0]
  
  tei_header = %{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE TEI.2 PUBLIC "-//TEI P5//DTD Main Document Type//EN" "http://www.tei-c.org/Guidelines/DTD/tei2.dtd" [
<!ENTITY % TEI.prose 'INCLUDE'>
<!ENTITY % TEI.linking 'INCLUDE'>
<!ENTITY % TEI.figures 'INCLUDE'>
<!ENTITY % TEI.analysis 'INCLUDE'>
<!ENTITY % TEI.XML 'INCLUDE'>
<!ENTITY % ISOlat1 SYSTEM 'http://www.tei-c.org/Entity_Sets/Unicode/iso-lat1.ent'>
%ISOlat1;
<!ENTITY % ISOlat2 SYSTEM 'http://www.tei-c.org/Entity_Sets/Unicode/iso-lat2.ent'>
%ISOlat2;
<!ENTITY % ISOnum SYSTEM 'http://www.tei-c.org/Entity_Sets/Unicode/iso-num.ent'>
%ISOnum;
<!ENTITY % ISOpub SYSTEM 'http://www.tei-c.org/Entity_Sets/Unicode/iso-pub.ent'>
%ISOpub;
]>
<TEI.2 lang="hr-HR">
<teiHeader>
<fileDesc>
<titleStmt>
<title>#{@title}</title>
<author>#{@author}</author>
</titleStmt>
<editionStmt>
<edition>
<date>#{@date}</date>
</edition>
</editionStmt>
<publicationStmt>
<authority/>
<address/>
</publicationStmt>
<sourceDesc>
<p>Brankov diplomski</p>
</sourceDesc>
</fileDesc>
<profileDesc>
<langUsage default="NO">
<language id="hr-HR">ISO hr-HR</language>
</langUsage>
</profileDesc>
<revisionDesc>
<change>
<date/>
<respStmt>
<name/>
</respStmt>
<item>revision</item>
</change>
</revisionDesc>
</teiHeader>
<text>
}
  
  # spajanje headera s pročišćenim XML-om
  final_output = tei_header + tei_xml + "\n</text>\n</TEI.2>"
  
  # ovdje se dokument sprema lokalno
  begin
    open("output_test/#{@title.to_ascii}.xml", "w") { |line| line.puts final_output }  
  rescue Errno::ENAMETOOLONG => e
    dump_error("#{@year}/#{@id}: nije parsiran zbog predugog imena\n")
    next
  rescue Errno::ENOENT => e
    dump_error("#{@year}/#{@id}: nije parsiran zbog ilegalnih znakova u imenu\n")
    next
  end
  
  puts @title
  puts @date
  puts @author
end
