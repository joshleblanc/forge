class User < ApplicationRecord
  has_secure_password
  
  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 30 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  
  def remember_token
    @remember_token ||= SecureRandom.hex(32)
  end

  def to_json(options = {})
    super(options.merge(except: [:password_digest]))
  end
end
