require 'rails_helper'

RSpec.describe AllTimeRecords, type: :service do
  # West Germany folds into Germany (its successor) for every team board.
  let(:germany)      { create(:team, :germany) }
  let(:west_germany) { create(:team, :west_germany, successor_team: germany) }
  let(:brazil)       { create(:team, name: "Brazil", fifa_code: "BRA", flag_emoji: "🇧🇷") }
  let(:france)       { create(:team, name: "France", fifa_code: "FRA") }

  def board_for(boards, key)
    boards.find { |b| b.key == key }
  end

  describe "#player_boards" do
    it "ranks players by tournament participations" do
      t1 = create(:tournament, year: 2014)
      t2 = create(:tournament, year: 2018)
      veteran = create(:player, name: "Veteran")
      rookie  = create(:player, name: "Rookie")
      create(:tournament_participation, player: veteran, tournament: t1)
      create(:tournament_participation, player: veteran, tournament: t2)
      create(:tournament_participation, player: rookie,  tournament: t1)

      board = board_for(described_class.new.player_boards, :participations)
      expect(board.entries.map { |e| [e.entity.name, e.count] })
        .to eq([["Veteran", 2], ["Rookie", 1]])
    end

    it "counts only the tournaments a player won with their nation" do
      wc1954 = create(:tournament, year: 1954, winner_team: west_germany)
      wc2014 = create(:tournament, year: 2014, winner_team: germany)
      wc2018 = create(:tournament, year: 2018, winner_team: france)

      mueller = create(:player, name: "Müller", nationality_team: germany)
      create(:tournament_participation, player: mueller, tournament: wc2014) # won
      create(:tournament_participation, player: mueller, tournament: wc2018) # France won — not Müller

      kaiser = create(:player, name: "Beckenbauer", nationality_team: west_germany)
      create(:tournament_participation, player: kaiser, tournament: wc1954) # won

      board = board_for(described_class.new.player_boards, :titles)
      expect(board.entries.map { |e| [e.entity.name, e.count] })
        .to contain_exactly(["Beckenbauer", 1], ["Müller", 1])
    end

    it "ranks players by goals, excluding own goals" do
      t = create(:tournament, year: 2014)
      m = create(:match, tournament: t, home_team: brazil, away_team: france)
      striker  = create(:player, name: "Striker",  nationality_team: brazil)
      defender = create(:player, name: "Defender", nationality_team: brazil)
      create(:goal, match: m, player: striker, scoring_team: brazil, minute: 10)
      create(:goal, match: m, player: striker, scoring_team: brazil, minute: 20)
      # An own goal is credited to the opponent, so it must not count for the scorer.
      create(:goal, :own_goal, match: m, player: defender, scoring_team: france, minute: 30)

      board = board_for(described_class.new.player_boards, :goals)
      expect(board.entries.map { |e| [e.entity.name, e.count] }).to eq([["Striker", 2]])
    end

    it "counts matches where a player scored three or more goals as hat-tricks" do
      t  = create(:tournament, year: 2014)
      m1 = create(:match, tournament: t, home_team: brazil, away_team: france, match_number: 1)
      m2 = create(:match, tournament: t, home_team: brazil, away_team: france,
                          match_number: 2, date: Date.new(2014, 6, 20))
      hero = create(:player, name: "Hat Hero", nationality_team: brazil)
      3.times { |i| create(:goal, match: m1, player: hero, scoring_team: brazil, minute: 10 + i, goal_order: i) }
      4.times { |i| create(:goal, match: m2, player: hero, scoring_team: brazil, minute: 10 + i, goal_order: i) }

      bracer = create(:player, name: "Brace Only", nationality_team: brazil)
      2.times { |i| create(:goal, match: m1, player: bracer, scoring_team: brazil, minute: 50 + i, goal_order: 10 + i) }

      board = board_for(described_class.new.player_boards, :hat_tricks)
      expect(board.entries.map { |e| [e.entity.name, e.count] }).to eq([["Hat Hero", 2]])
    end

    it "honours the limit" do
      t = create(:tournament, year: 2014)
      6.times { |i| create(:tournament_participation, player: create(:player, name: "P#{i}"), tournament: t) }

      board = board_for(described_class.new(limit: 3).player_boards, :participations)
      expect(board.entries.size).to eq(3)
    end
  end

  describe "#team_boards" do
    it "ranks teams by matches played, merging predecessors and excluding scheduled fixtures" do
      t = create(:tournament, year: 2014)
      create(:match, tournament: t, home_team: west_germany, away_team: brazil, match_number: 1)
      create(:match, tournament: t, home_team: germany, away_team: france,
                     match_number: 2, date: Date.new(2014, 6, 21))
      # Pre-loaded but unplayed fixture — must be ignored.
      create(:match, tournament: t, home_team: germany, away_team: brazil,
                     match_number: 3, result_type: :scheduled, date: Date.new(2014, 6, 22))

      board = board_for(described_class.new.team_boards, :matches)
      expect(board.entries.find { |e| e.entity == germany }.count).to eq(2)
      expect(board.entries.find { |e| e.entity == brazil }.count).to eq(1)
    end

    it "ranks teams by matches won" do
      t = create(:tournament, year: 2014)
      create(:match, tournament: t, home_team: germany, away_team: brazil,
                     winner_team: germany, match_number: 1)
      create(:match, tournament: t, home_team: west_germany, away_team: france,
                     winner_team: west_germany, match_number: 2, date: Date.new(2014, 6, 21))
      create(:match, tournament: t, home_team: brazil, away_team: france,
                     winner_team: france, match_number: 3, date: Date.new(2014, 6, 22))

      board = board_for(described_class.new.team_boards, :wins)
      expect(board.entries.find { |e| e.entity == germany }.count).to eq(2)
    end

    it "sums team goals from match scores, extra-time aware and family-merged" do
      t = create(:tournament, year: 2014)
      create(:match, tournament: t, home_team: germany, away_team: brazil,
                     home_score: 2, away_score: 1, winner_team: germany, match_number: 1)
      create(:match, tournament: t, home_team: west_germany, away_team: france,
                     home_score: 1, away_score: 1,
                     home_score_after_extra_time: 3, away_score_after_extra_time: 1,
                     result_type: :after_extra_time, winner_team: west_germany,
                     match_number: 2, date: Date.new(2014, 6, 21))

      board = board_for(described_class.new.team_boards, :goals)
      # 2 (Germany) + 3 (West Germany, after extra time) folded into Germany.
      expect(board.entries.find { |e| e.entity == germany }.count).to eq(5)
    end

    it "counts distinct tournaments a nation appeared in" do
      t1 = create(:tournament, year: 2010)
      t2 = create(:tournament, year: 2014)
      create(:match, tournament: t1, home_team: west_germany, away_team: brazil, match_number: 1)
      create(:match, tournament: t1, home_team: germany, away_team: france,
                     match_number: 2, date: Date.new(2010, 6, 15))
      create(:match, tournament: t2, home_team: germany, away_team: brazil, match_number: 1)

      board = board_for(described_class.new.team_boards, :presences)
      # Present in 2010 and 2014 — the two 2010 appearances don't double-count.
      expect(board.entries.find { |e| e.entity == germany }.count).to eq(2)
    end

    it "merges predecessor titles into the successor nation" do
      create(:tournament, year: 1954, winner_team: west_germany)
      create(:tournament, year: 2014, winner_team: germany)
      create(:tournament, year: 1970, winner_team: brazil)

      board = board_for(described_class.new.team_boards, :titles)
      counts = board.entries.map { |e| [e.entity.name, e.count] }
      expect(counts).to include(["Germany", 2])
      expect(counts).to include(["Brazil", 1])
    end
  end
end
