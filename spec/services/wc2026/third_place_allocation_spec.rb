require "rails_helper"

RSpec.describe Wc2026::ThirdPlaceAllocation do
  # Per-slot allowed third-place groups, from the FIFA schedule (match X's
  # reserved third-place slot only accepts a third from these groups).
  ALLOWED = {
    74 => %w[A B C D F], 77 => %w[C D F G H], 79 => %w[C E F H I], 80 => %w[E H I J K],
    81 => %w[B E F I J], 82 => %w[A E H I J], 85 => %w[E F G I J], 87 => %w[D E I J L]
  }.freeze

  describe ".table" do
    it "loads all 495 combinations" do
      expect(described_class.table.size).to eq(495)
    end
  end

  describe ".for" do
    it "matches the official table for the first combination (E F G H I J K L)" do
      result = described_class.for(%w[E F G H I J K L])
      expect(result).to eq(
        74 => "F", 77 => "G", 79 => "E", 80 => "K",
        81 => "I", 82 => "H", 85 => "J", 87 => "L"
      )
    end

    it "assigns every group within its slot's allowed set, across all 495 rows" do
      described_class.table.each do |combo, mapping|
        mapping.each do |match, group|
          expect(ALLOWED[match]).to include(group),
            "combo #{combo}: match #{match} got #{group}, allowed #{ALLOWED[match].inspect}"
        end
      end
    end

    it "permutes exactly the qualifying groups (no group used twice or dropped)" do
      described_class.table.each do |combo, mapping|
        expect(mapping.values.sort.join).to eq(combo)
      end
    end

    it "is order-insensitive about the input groups" do
      expect(described_class.for(%w[L K J I H G F E])).to eq(described_class.for(%w[E F G H I J K L]))
    end

    it "raises on the wrong number of groups" do
      expect { described_class.for(%w[A B C]) }.to raise_error(ArgumentError)
    end

    it "raises for a combination outside the table" do
      # Valid count/letters but a sorted key the table can't contain is impossible
      # (every 8-subset exists), so an invalid letter is the way to miss.
      expect { described_class.for(%w[A B C D E F G Z]) }.to raise_error(ArgumentError)
    end
  end
end
