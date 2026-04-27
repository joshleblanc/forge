class PackageVersion < ApplicationRecord
  belongs_to :package
  has_one_attached :zip_file

  validates :version, presence: true
  validates :version, uniqueness: { scope: :package_id }

  scope :ordered, -> { order(Gem::Version.new(version)) }
end
