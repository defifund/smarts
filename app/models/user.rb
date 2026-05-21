class User < ApplicationRecord
  API_TOKEN_PREFIX_LENGTH = 12

  attr_reader :plain_api_token

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :articles, dependent: :restrict_with_error

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, :email_address, :api_token_prefix, :api_token_digest, presence: true
  validates :email_address, uniqueness: true

  before_validation :ensure_api_token, on: :create

  class << self
    def generate_api_token
      "sma_#{SecureRandom.urlsafe_base64(32)}"
    end

    def authenticate_api_token(token)
      token = token.to_s
      return nil if token.blank?

      where(api_token_prefix: token.first(API_TOKEN_PREFIX_LENGTH)).find do |user|
        BCrypt::Password.new(user.api_token_digest).is_password?(token)
      rescue BCrypt::Errors::InvalidHash
        false
      end
    end
  end

  def rotate_api_token!
    token = self.class.generate_api_token
    update!(
      api_token_prefix: token.first(API_TOKEN_PREFIX_LENGTH),
      api_token_digest: BCrypt::Password.create(token)
    )
    token
  end

  private

  def ensure_api_token
    return if api_token_prefix.present? && api_token_digest.present?

    token = self.class.generate_api_token
    @plain_api_token = token
    self.api_token_prefix = token.first(API_TOKEN_PREFIX_LENGTH)
    self.api_token_digest = BCrypt::Password.create(token)
  end
end
