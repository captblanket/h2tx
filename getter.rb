#!/usr/bin/ruby -w
require "open-uri"
require "yaml"


def serialize(object)
  open("uris.yaml", "w") { |f| YAML.dump(object, f) }
end


def extract_uris
  doc_uris = []
  n = 0
  text = ""
  puts "\nSpajam se na HIDRA-in poslužitelj.\n\n"
  
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
  return doc_uris
end


def get_uris
  if File.exists?("uris.yaml")
    loaded_uris = open("uris.yaml") { |f| YAML.load(f) }
    extracted_uris = extract_uris
    if loaded_uris.size == extracted_uris.size
      puts "Nema novih dokumenata.\n\n"
    else
      difference = extracted_uris - loaded_uris
      puts "\nNađeno #{difference.size} dokumenata.\n\n"
      return difference
    end
  
  else 
    puts "\nPokrećem prvi put...\n"
    extraction = extract_uris
    puts "\nNađeno #{extraction.size} dokumenata.\n\n"
    serialize(extraction)
    return extraction
  end
end

get_uris
