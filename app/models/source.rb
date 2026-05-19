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
