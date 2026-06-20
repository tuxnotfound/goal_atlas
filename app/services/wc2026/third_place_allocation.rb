require "csv"

module Wc2026
  # Maps the 8 best third-placed groups to their Round-of-32 slots using FIFA's
  # official allocation table (db/data/wc2026/third_place_allocation.csv, the
  # full 495-combination lookup transcribed from the FIFA regulations / the
  # Wikipedia "2026 FIFA World Cup third-place table").
  #
  #   Wc2026::ThirdPlaceAllocation.for(%w[A C D E G I J L])
  #   # => { 74 => "C", 77 => "D", 79 => "E", 80 => "I", 81 => "J", 82 => "A", 85 => "G", 87 => "L" }
  #
  # The value at each slot is the *group letter* whose third-placed team fills
  # that match's reserved third-place slot.
  class ThirdPlaceAllocation
    PATH = Rails.root.join("db/data/wc2026/third_place_allocation.csv")

    # The 8 Round-of-32 matches that host a third-placed team.
    SLOT_MATCHES = [74, 77, 79, 80, 81, 82, 85, 87].freeze

    class << self
      def for(qualified_groups)
        key = normalize(qualified_groups)
        table.fetch(key) { raise KeyError, "no third-place allocation for combination #{key.inspect}" }
      end

      def table
        @table ||= load_table
      end

      private

      def normalize(groups)
        letters = groups.map { |g| g.to_s.upcase }.sort
        unless letters.size == 8 && letters.uniq.size == 8 && letters.all? { |l| ("A".."L").include?(l) }
          raise ArgumentError, "expected 8 distinct groups in A–L, got #{groups.inspect}"
        end
        letters.join
      end

      def load_table
        CSV.read(PATH, headers: true).each_with_object({}) do |row, h|
          h[row["groups"]] = SLOT_MATCHES.index_with { |m| row["m#{m}"] }
        end
      end
    end
  end
end
