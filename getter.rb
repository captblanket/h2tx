require "open-uri"
require "yaml"


URIS_FILE = "uris.yml"

def serialize(object, file_name)
  open(file_name, "w") { |f| YAML.dump(object, f) }
end

def deserialize(file_name)
  open(file_name) { |f| YAML.load(f) }
end

def extract_uris
  doc_uris = []
  n = 0
  text = ""
  puts "\nSpajam se na HIDRA-in poslužitelj.\n\n"
  
  # pošto server do besvijesti vraća istu zadnju stranicu (npr. offset=27 je isto što i offset=789),
  # petlja procesira URL-ove sve dok server ne vrati dvije iste zaredom
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
  
  # ne želimo ugniježdena polja i duplikate
  doc_uris.flatten!
  return doc_uris.uniq!
end


def get_uris
  # provjeri postoje li lokalni URL-ovi i ako da, loadaj ih
  if File.exists?(URIS_FILE)
    loaded_uris = deserialize(URIS_FILE)
    extracted_uris = extract_uris
    
    # usporedi lokalne i nove URL-ove; vrati ništa ili njihovu razliku
    if loaded_uris == extracted_uris
      puts "\nNema novih dokumenata.\n\n"
    else
      difference = extracted_uris - loaded_uris
      puts "\nBroj nađenih dokumenata: #{difference.size}\n\n"
      serialize(extracted_uris, URIS_FILE)
      return difference
    end
  
  # ako nema lokalnih URL-ova, pokreni novu ekstrakciju i serijaliziraj
  else 
    puts "\nPokrećem prvi put...\n"
    extraction = extract_uris
    puts "\nBroj nađenih dokumenata: #{extraction.size}\n\n"
    serialize(extraction, URIS_FILE)
    return extraction
  end
end

get_uris
