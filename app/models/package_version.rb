class PackageVersion < ApplicationRecord
  belongs_to :package
  validates :version, presence: true
  validates :version, uniqueness: { scope: :package_id }

  scope :ordered, -> { order(Gem::Version.new(version)) }
end
