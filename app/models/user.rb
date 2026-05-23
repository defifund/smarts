class User < ApplicationRecord
  API_TOKEN_PREFIX_LENGTH = 12
  ROLES = %w[user admin].freeze

  attr_reader :plain_api_token

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :articles, dependent: :restrict_with_error

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, :email_address, :api_token_prefix, :api_token_digest, presence: true
  validates :email_address, uniqueness: true
  validates :role, inclusion: { in: ROLES }

  before_validation :default_role
  before_validation :ensure_api_token, on: :create

  class << self
    def generate_api_token
      "sma_#{SecureRandom.urlsafe_base64(32)}"
    end

    def default_role_for_new_user(environment: Rails.env, existing_users_count: none.count)
      environment.development? && existing_users_count.zero? ? "admin" : "user"
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

  def admin?
    role == "admin"
  end

  private

  def default_role
    return if role.present?

    self.role = self.class.default_role_for_new_user
  end

  def ensure_api_token
    return if api_token_prefix.present? && api_token_digest.present?

    token = self.class.generate_api_token
    @plain_api_token = token
    self.api_token_prefix = token.first(API_TOKEN_PREFIX_LENGTH)
    self.api_token_digest = BCrypt::Password.create(token)
  end
end
