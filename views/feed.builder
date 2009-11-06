author = lambda {
  xml.name  ShitStorm::App.name
  xml.email ShitStorm::App.email
  xml.uri   ShitStorm::App.url
}

xml.instruct! :xml, :version => "1.0"
xml.feed :xmlns => "http://www.w3.org/2005/Atom" do
  xml.id ShitStorm::App.url
  xml.title dict[:log_name] % ShitStorm::App.name
  if @entries.first
    xml.updated @entries.first.ctime.xmlschema
  else
    xml.updated Time.now.xmlschema
  end
  xml.link :href => ShitStorm::App.url
  xml.link :rel => "self", :href => File.join(ShitStorm::App.url, 'feed')
  xml.author &author

  @entries.each do |entry|
    xml.entry do
      xml.id entry.url
      xml.title entry.title, :type => "html"
      xml.updated entry.ctime.xmlschema
      xml.author &author
      xml.link :rel => "alternate", :href => entry.url
      xml.summary :type => "xhtml" do
        xml.div :xmlns => "http://www.w3.org/1999/xhtml" do
          xml << entry.contents
        end
      end
    end
  end
end
