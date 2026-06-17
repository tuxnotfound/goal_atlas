xml.instruct! :xml, version: "1.0"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url do
    xml.loc root_url
    xml.changefreq "weekly"
    xml.priority "1.0"
  end

  [tournaments_url, matches_url, goals_url, records_url].each do |loc|
    xml.url do
      xml.loc loc
      xml.changefreq "weekly"
      xml.priority "0.9"
    end
  end

  @tournaments.each do |t|
    xml.url do
      xml.loc tournament_url(t)
      xml.lastmod t.updated_at.iso8601
      xml.changefreq "monthly"
      xml.priority "0.9"
    end
  end

  @matches.each do |m|
    xml.url do
      xml.loc match_url(m)
      xml.lastmod m.updated_at.iso8601
      xml.changefreq "yearly"
      xml.priority "0.7"
    end
  end

  @goals.each do |g|
    xml.url do
      xml.loc goal_url(g)
      xml.lastmod g.updated_at.iso8601
      xml.changefreq "yearly"
      xml.priority "0.6"
    end
  end

  @players.each do |p|
    xml.url do
      xml.loc player_url(p)
      xml.lastmod p.updated_at.iso8601
      xml.changefreq "yearly"
      xml.priority "0.7"
    end
  end

  @teams.each do |t|
    xml.url do
      xml.loc team_url(t)
      xml.lastmod t.updated_at.iso8601
      xml.changefreq "yearly"
      xml.priority "0.7"
    end
  end
end
