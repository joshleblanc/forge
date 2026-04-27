class User < ApplicationRecord
  has_secure_password
  has_many :api_keys, dependent: :destroy

  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 30 }, unless: :anonymous?
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }, unless: :anonymous?
  validates :password, length: { minimum: 8 }, if: -> { password.present? && !anonymous? }

  scope :anonymous, -> { where(anonymous: true) }

  def anonymous?
    anonymous == true
  end

  def remember_token
    @remember_token ||= SecureRandom.hex(32)
  end

  def to_json(options = {})
    super(options.merge(except: [:password_digest]))
  end
end
