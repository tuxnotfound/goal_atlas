require "rails_helper"
require "yaml"

RSpec.describe Wc2026BracketPopulator do
  let(:tournament) { create(:tournament, year: 2026) }

  # 12 groups A–L, four teams each ("A0".."L3"). Within every group a full
  # round-robin makes the order strict: g0 (winner) > g1 (runner-up) > g2
  # (third) > g3. All twelve thirds end identical, so the best-8 tie-break by
  # group letter -> groups A–H supply the qualifying thirds.
  before do
    @teams = {}
    @mn = 0
    ("A".."L").each do |g|
      members = (0..3).map { |i| find_team("#{g}#{i}") }
      members.combination(2).each do |stronger, weaker|
        win(g, stronger, weaker) # listed strongest-first, so g0 beats all, etc.
      end
    end

    r32_entries.each do |e|
      create(:match, tournament: tournament, stage: :round_of_32, result_type: :scheduled,
                     match_number: e["match_number"], date: e["date"],
                     home_source_label: e["home"], away_source_label: e["away"],
                     home_team: nil, away_team: nil)
    end
  end

  def find_team(code)
    @teams[code] ||= create(:team, name: code, fifa_code: "#{code}X", country_code: code)
  end

  def win(group, home, away)
    @mn += 1
    create(:match, tournament: tournament, stage: :group_stage, group_letter: group,
                   home_team: home, away_team: away, home_score: 1, away_score: 0,
                   winner_team: home, result_type: :regulation, match_number: @mn)
  end

  def r32_entries
    YAML.load_file(Rails.root.join("db/data/wc2026/knockout.yml"), permitted_classes: [Date])
        .select { |e| e["stage"] == "round_of_32" }
  end

  def r32 = Match.where(tournament: tournament, stage: :round_of_32).index_by(&:match_number)

  it "fills all 16 Round-of-32 matches with two teams each" do
    described_class.call
    matches = r32.values
    expect(matches.size).to eq(16)
    expect(matches).to all(be_valid)
    matches.each do |m|
      expect(m.home_team).to be_present, "match #{m.match_number} home unfilled"
      expect(m.away_team).to be_present, "match #{m.match_number} away unfilled"
    end
  end

  it "places group winners and runners-up in the right positional slots" do
    described_class.call
    # Match 73 = Runner-up A vs Runner-up B
    expect(r32[73].home_team).to eq(@teams["A1"])
    expect(r32[73].away_team).to eq(@teams["B1"])
    # Match 74 home = Winner E
    expect(r32[74].home_team).to eq(@teams["E0"])
    # Match 79 home = Winner A
    expect(r32[79].home_team).to eq(@teams["A0"])
  end

  it "fills third-place slots from the eight best thirds (groups A–H here)" do
    described_class.call
    third_slots = Wc2026::ThirdPlaceAllocation::SLOT_MATCHES
    qualifying_thirds = ("A".."H").map { |g| @teams["#{g}2"] }

    third_slots.each do |n|
      away = r32[n].away_team
      expect(qualifying_thirds).to include(away),
        "match #{n} third slot got #{away&.name}, expected one of A2–H2"
    end
  end

  it "is re-runnable and reflects updated standings" do
    described_class.call
    expect(r32[74].home_team).to eq(@teams["E0"])

    # Flip group E: make E1 the winner by giving it a dominant result.
    Match.where(tournament: tournament, group_letter: "E").delete_all
    win("E", @teams["E1"], @teams["E0"])

    described_class.call
    expect(Match.find(r32[74].id).home_team).to eq(@teams["E1"])
  end
end
