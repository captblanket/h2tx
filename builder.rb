require "getter"
require "parser"
require "erb"

# simulacije gettera
# uris_to_parse = deserialize(URIS_FILE)
# uris_to_parse = ["input_test_2000.htm"]
uris_to_parse = ["http://www.nn.hr/clanci/sluzbeno/2005/0793.htm"]

puts "Počinjem parsiranje"
uris_to_parse.each do |source|
  puts "------------------------------------------------------------------------"
  
  # prvo dobij ID i godinu (korisno za hvatanje grešaka)
  meta_info = source.scan(%r{http://www.nn.hr/clanci/sluzbeno/(\d{4})/(\d{4,}).html?}).flatten
  @year = meta_info[0]
  @id = meta_info[1]
  
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
  tei_output = ERB.new(tei_template, nil, "", "tei_output").result(binding)
  meta_template = open("meta_template.rtxt") { |line| line.read }
  meta_output = ERB.new(meta_template, nil, "", "meta_output").result(binding)
  
  puts @title
  puts @date
  puts @author
  
  # spremi dokumente lokalno
  begin
    new_dir = "output/#{@year}-#{@id}"
    Dir.mkdir(new_dir) unless File.directory?(new_dir)
    open(new_dir + "/#{@title.to_ascii}.xml", "w") { |line| line.puts tei_output }
    open(new_dir + "/meta.txt", "w") { |line| line.puts meta_output }
  rescue Errno::ENAMETOOLONG => e
    @title = @title.truncate
    retry
  rescue Errno::ENOENT => e
    dump_error("nije spremljen zbog ilegalnih znakova u imenu")
    next
  end
end
