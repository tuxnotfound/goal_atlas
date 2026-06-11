class Team < ApplicationRecord
  include Discard::Model

  extend FriendlyId
  friendly_id :name, use: :slugged

  CONFEDERATIONS = {
    uefa: 0,
    conmebol: 1,
    concacaf: 2,
    afc: 3,
    caf: 4,
    ofc: 5
  }.freeze

  enum :confederation, CONFEDERATIONS

  belongs_to :successor_team, class_name: "Team", optional: true
  has_many :predecessor_teams, class_name: "Team", foreign_key: :successor_team_id, dependent: :nullify, inverse_of: :successor_team

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :country_code, presence: true, length: { in: 2..3 }
  validates :fifa_code, length: { is: 3 }, allow_blank: true

  scope :active_in_year, ->(year) {
    where("(active_from IS NULL OR active_from <= ?) AND (active_until IS NULL OR active_until >= ?)", year, year)
  }

  # IDs to aggregate on this team's public page: self + any predecessor teams
  # that have us as their successor. E.g. Germany.family_ids returns
  # [GER, FRG, GDR] so the team page shows the unified history.
  def family_ids
    [id, *predecessor_teams.kept.pluck(:id)].uniq
  end
end

# == Schema Information
#
# Table name: teams
#
#  id                :bigint           not null, primary key
#  active_from       :integer
#  active_until      :integer
#  confederation     :integer          not null
#  country_code      :string           not null
#  discarded_at      :datetime
#  fifa_code         :string
#  flag_emoji        :string
#  name              :string           not null
#  slug              :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  successor_team_id :bigint
#
# Indexes
#
#  index_teams_on_country_code       (country_code)
#  index_teams_on_discarded_at       (discarded_at)
#  index_teams_on_name               (name)
#  index_teams_on_name_trgm          (name) USING gin
#  index_teams_on_slug               (slug) UNIQUE
#  index_teams_on_successor_team_id  (successor_team_id)
#
# Foreign Keys
#
#  fk_rails_...  (successor_team_id => teams.id)
#
