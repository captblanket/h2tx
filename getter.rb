require "open-uri"
require "yaml"


def serialize(object)
  open("uris.yaml", "w") { |f| YAML.dump(object, f) }
end

# getter mora znati koji su novi a koji vec procesirani

def extract_uris
  doc_uris = []
  n = 0
  text = ""
  
  while doc_uris.uniq == doc_uris
    uri = "http://hidra.srce.hr/webpac-hidra-bib/?show_full=Prika%BEi+detalje%21&rm=results&f15=Collection&v15=NA+SNAZI+uskla&filter=hidra-sdrh-h;PAGER_offset=" + (n += 1).to_s
    begin
      text = open(uri).read
      puts "Dohvaćam..."
    rescue SocketError => e
      puts "\nNe mogu se spojiti na HIDRA-in poslužitelj.\n"
      break
    end
    doc_uris << text.scan(%r{http://www.nn.hr/clanci/sluzbeno/\d{4}/\d{4,}.html?})
  end
  
  doc_uris.flatten!
  puts "\nNađeno #{doc_uris.size} dokumenata.\n\n"
  serialize(doc_uris)
  return doc_uris
end

extract_uris