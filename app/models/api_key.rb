class ApiKey < ApplicationRecord
  belongs_to :user, optional: true

  before_validation :generate_key, on: :create

  validates :key, uniqueness: true, presence: true
  validates :name, presence: true

  def anonymous?
    user.nil?
  end

  def can_publish?
    !anonymous?
  end

  def display_name
    return name if name.present?
    return "Anonymous Project #{id}" if anonymous?
    user&.username || "API Key #{id}"
  end

  def regenerate_key!
    update!(key: self.class.generate_key_value)
  end

  def self.generate_key_value
    "fk_live_#{SecureRandom.hex(24)}"
  end

  def self.find_by_key(key)
    find_by(key: key)
  end

  private

  def generate_key
    self.key ||= self.class.generate_key_value
  end
end
