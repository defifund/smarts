# frozen_string_literal: true

class Account < ApplicationRecord
  PROVIDERS = %w[x].freeze

  belongs_to :user

  encrypts :access_token
  encrypts :access_token_secret

  validates :provider, :handle, :locale, :access_token, :access_token_secret, presence: true
  validates :provider, inclusion: { in: PROVIDERS }
  validates :locale, inclusion: { in: Article::SUPPORTED_LOCALES }
  validates :locale, uniqueness: { scope: [ :user_id, :provider ] }
end
