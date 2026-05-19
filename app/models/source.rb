class Source < ApplicationRecord
  include Discard::Model

  RELIABILITIES = {
    official: 0,
    high: 1,
    medium: 2,
    disputed: 3
  }.freeze

  enum :reliability, RELIABILITIES

  validates :name, presence: true, uniqueness: true
  validates :reliability, presence: true
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
end

# == Schema Information
#
# Table name: sources
#
#  id           :bigint           not null, primary key
#  discarded_at :datetime
#  name         :string           not null
#  notes        :text
#  reliability  :integer          not null
#  url          :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_sources_on_discarded_at  (discarded_at)
#  index_sources_on_name          (name) UNIQUE
#
