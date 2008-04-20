require "getter"
require "parser"
require "erb"

# simulacije gettera
# uris_to_parse = ["input_test_2000.htm", "input_test_2001.htm", "input_test_2002.htm", "input_test_2003.htm", "input_test_2004.htm", \
#                 "input_test_2005.htm", "input_test_2006.htm", "input_test_2007.htm", "input_test_2008.htm"]
# uris_to_parse = deserialize(URIS_FILE)
# uris_to_parse = ["input_test_2000.htm"]
uris_to_parse = ["http://www.nn.hr/clanci/sluzbeno/2005/0793.htm"]

puts "Počinjem parsiranje"
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
    puts "\nNe mogu se spojiti na poslužitelj Narodnih novina."
    break
  rescue OpenURI::HTTPError => e
    dump_error("traženi dokument ne postoji")
    next
  end

  # konverzija i čišćenje
  html_utf8 = convert_to_utf8(loaded_html)
  xml = tidy_html(html_utf8) 
  tei_xml = conform_to_tei(xml)[0]
  
  # učitaj template i napravi supstitucije
  tei_template = open("tei_template.rxml") { |line| line.read }
  final_output = ERB.new(tei_template, nil, "", "final_output").result(binding)

  puts @title
  puts @date
  puts @author
  
  # spremi dokument lokalno
  begin
    open("#{@title.to_ascii}.xml", "w") { |line| line.puts final_output }
  rescue Errno::ENAMETOOLONG => e
    @title = @title.truncate
    retry
  rescue Errno::ENOENT => e
    dump_error("nije spremljen zbog ilegalnih znakova u imenu")
    next
  end
end
