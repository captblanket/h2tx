require "open-uri"
require "yaml"

def get_uris
    text = ""
    pages.each do |uri|
      begin
        text << open(uri).read
        puts "Dohvaćam..."
      rescue SocketError => e
        puts "\nNe mogu se spojiti na HIDRA-in poslužitelj.\n"
        break
      end
    end
    doc_uris = text.scan(%r{http://www.nn.hr/clanci/sluzbeno/\d{4}/\d{4,}.html?})
    puts "\nNađeno #{doc_uris.uniq.size} dokumenata.\n\n"
    serialize(doc_uris)
    return doc_uris.uniq! # make sure there are no duplicate URIs
end

def pages
  generated_uris = []
  (1..2).each do |num|    # ima ih 25
    generated_uris << "http://hidra.srce.hr/webpac-hidra-bib/?show_full=Prika%BEi+detalje%21&rm=results&f15=Collection&v15=NA+SNAZI+uskla&filter=hidra-sdrh-h;PAGER_offset=" + num.to_s
  end
  return generated_uris
end

def serialize(object)
  open("uris.yaml", "w") { |f| YAML.dump(object, f) }
end

get_uris