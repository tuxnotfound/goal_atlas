require "rails_helper"

RSpec.describe GroupStandings do
  let(:tournament) { create(:tournament, year: 2026) }

  def team(name) = create(:team, name: name, fifa_code: name[0, 3].upcase)

  def played(home, away, hs, as)
    winner = hs > as ? home : (as > hs ? away : nil)
    create(:match, tournament: tournament, stage: :group_stage, group_letter: "A",
                   home_team: home, away_team: away, home_score: hs, away_score: as,
                   winner_team: winner, result_type: :regulation, match_number: rand(1000))
  end

  it "ranks by points, then goal difference, then goals for" do
    a = team("Alpha"); b = team("Bravo"); c = team("Charlie")
    played(a, b, 3, 0)   # a +3
    played(b, c, 2, 1)   # b beats c
    played(c, a, 1, 0)   # c beats a

    rows = described_class.call(Match.where(tournament: tournament))["A"]
    # a: 3pts gd+2; b: 3pts gd-1; c: 3pts gd-1 gf2 vs b gf... all 3pts -> gd then gf
    expect(rows.map { |r| r[:team] }.first).to eq(a) # best gd
    expect(rows.map { |r| r[:pts] }).to all(eq(3))
  end

  it "lists scheduled teams without crediting points" do
    a = team("Alpha"); b = team("Bravo")
    create(:match, tournament: tournament, stage: :group_stage, group_letter: "A",
                   home_team: a, away_team: b, result_type: :scheduled, match_number: 1)
    rows = described_class.call(Match.where(tournament: tournament))["A"]
    expect(rows.size).to eq(2)
    expect(rows.map { |r| r[:pts] }).to all(eq(0))
    expect(rows.map { |r| r[:p] }).to all(eq(0))
  end
end
