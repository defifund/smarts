xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  @sitemap.entries.each do |entry|
    xml.url do
      xml.loc entry[:loc]
      xml.changefreq entry[:changefreq]
      xml.priority entry[:priority]
    end
  end
end
