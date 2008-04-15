require "test/unit"
require "yaml"
require "getter"

class TestGetter < Test::Unit::TestCase
  def test_get_uris
    expected = %w{http://www.nn.hr/clanci/sluzbeno/2000/1128.htm http://www.nn.hr/clanci/sluzbeno/2000/1257.htm http://www.nn.hr/clanci/sluzbeno/2008/0300.htm http://www.nn.hr/clanci/sluzbeno/2008/0172.htm http://www.nn.hr/clanci/sluzbeno/2008/0111.htm http://www.nn.hr/clanci/sluzbeno/2008/0113.htm http://www.nn.hr/clanci/sluzbeno/2008/0112.htm http://www.nn.hr/clanci/sluzbeno/2008/0115.htm http://www.nn.hr/clanci/sluzbeno/2008/0114.htm http://www.nn.hr/clanci/sluzbeno/2008/0081.htm http://www.nn.hr/clanci/sluzbeno/2008/0092.htm http://www.nn.hr/clanci/sluzbeno/2008/0067.htm http://www.nn.hr/clanci/sluzbeno/2008/0064.htm http://www.nn.hr/clanci/sluzbeno/2008/0065.htm http://www.nn.hr/clanci/sluzbeno/2008/0068.htm}
    loaded_uris = open("uris.yaml") { |f| YAML.load(f) }
    extracted_uris = extract_uris
    actual = extracted_uris - loaded_uris
    assert_equal(expected, actual)
  end
end

# kad pokreces test, zakomentiraj zadnju liniju gettera