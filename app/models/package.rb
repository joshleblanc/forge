class Package < ApplicationRecord
  has_many :versions, class_name: 'PackageVersion', dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
  validates :author, presence: true
  validates :latest_version, presence: true
  
  # Custom validation for semver format
  validate :valid_version_format
  
  # Name must be lowercase alphanumeric with underscores
  validates :name, format: { with: /\A[a-z][a-z0-9_]*\z/, message: "must start with a letter and contain only lowercase letters, numbers, and underscores" }

  scope :search, ->(query) {
    where("name LIKE ? OR description LIKE ?", "%#{query}%", "%#{query}%") if query.present?
  }

  scope :filter_by_tag, ->(tag) {
    # SQLite-compatible JSON array search
    where("tags LIKE ?", "%#{tag}%") if tag.present?
  }

  scope :ordered, -> { order(created_at: :desc) }

  private

  def valid_version_format
    return unless latest_version.present?
    
    # Basic semver validation
    unless latest_version.match?(/\A\d+\.\d+\.\d+([.-]\w+)?\z/)
      errors.add(:latest_version, "must follow semver format (e.g., 1.0.0)")
    end
  end
end
