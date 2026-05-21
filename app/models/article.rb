# frozen_string_literal: true

class Article < ApplicationRecord
  SUPPORTED_LOCALES = %w[en zh-CN zh-TW].freeze
  LOCALE_ROUTE_MAP = {
    "cn" => "zh-CN",
    "tw" => "zh-TW"
  }.freeze
  ROUTE_LOCALE_MAP = LOCALE_ROUTE_MAP.invert.freeze

  # Two-character article slugs. Anchored form for validation, unanchored
  # form for route constraints. Single source of truth — `config/routes.rb`
  # and `Articles::DraftReader` both reference these.
  SLUG_PATTERN = /[a-z0-9]{2}/
  SLUG_FORMAT = /\A#{SLUG_PATTERN.source}\z/

  # Two-character paths reserved by routing precedence (e.g. `/up` is the
  # Rails health check) or held for future top-level routes. Must stay in
  # sync with any non-article two-char route declared in `config/routes.rb`.
  RESERVED_SLUGS = %w[
    up
    ai
    go
    to
    my
    me
    in
    on
  ].freeze

  CATEGORIES = %w[
    product
    stablecoins
    risk
    markets
    guides
    company
  ].freeze

  SUBCATEGORIES = {
    "product" => %w[mcp tools workflows releases],
    "stablecoins" => %w[issuers reserves payments regulation infrastructure],
    "risk" => %w[admin-controls upgrades governance incidents compliance],
    "markets" => %w[polymarket prediction-markets liquidity resolution odds],
    "guides" => %w[setup integrations examples playbooks],
    "company" => %w[positioning updates roadmap]
  }.freeze

  belongs_to :user

  validates :slug, presence: true, uniqueness: true
  validates :slug, format: { with: SLUG_FORMAT, message: "must be exactly two lowercase letters or digits" }
  validates :slug, exclusion: { in: RESERVED_SLUGS }
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validate :subcategory_allowed_for_category
  validate :title_has_required_locale
  validate :content_has_required_locale

  before_validation :normalize_fields

  scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }

  class << self
    def locale_from_route(route_locale)
      return "en" if route_locale.blank?

      LOCALE_ROUTE_MAP.fetch(route_locale)
    end

    def route_locale_for(locale)
      ROUTE_LOCALE_MAP[locale]
    end
  end

  def published?
    published_at.present? && published_at <= Time.current
  end

  def available_locales
    content.to_h.select { |_locale, value| value.to_s.strip.present? }.keys
  end

  def locale_for(requested_locale)
    candidates = [ requested_locale, "en", *available_locales ].compact.uniq
    candidates.find { |locale| content_for(locale).present? }
  end

  def title_for(locale)
    localized_value(title, locale)
  end

  def summary_for(locale)
    localized_value(summary, locale)
  end

  def content_for(locale)
    localized_value(content, locale)
  end

  def public_path(locale = "en")
    route_locale = self.class.route_locale_for(locale)
    route_locale.present? ? "/#{route_locale}/#{slug}" : "/#{slug}"
  end

  private

  def normalize_fields
    self.slug = slug.to_s.strip if slug.present?
    self.category = category.to_s.strip if category.present?
    self.subcategory = subcategory.to_s.strip.presence
    self.title = normalized_locale_hash(title)
    self.summary = normalized_locale_hash(summary)
    self.content = normalized_locale_hash(content)
  end

  def normalized_locale_hash(value)
    return {} unless value.is_a?(Hash)

    value.each_with_object({}) do |(locale, text), hash|
      locale = locale.to_s
      next unless SUPPORTED_LOCALES.include?(locale)

      hash[locale] = text.to_s.strip
    end
  end

  def subcategory_allowed_for_category
    return if subcategory.blank?
    return if SUBCATEGORIES.fetch(category, []).include?(subcategory)

    errors.add(:subcategory, "is not allowed for #{category}")
  end

  def title_has_required_locale
    errors.add(:title, "must include en, zh-CN, or zh-TW") unless has_required_locale?(title)
  end

  def content_has_required_locale
    errors.add(:content, "must include en, zh-CN, or zh-TW") unless has_required_locale?(content)
  end

  def has_required_locale?(hash)
    SUPPORTED_LOCALES.any? { |locale| hash.to_h[locale].to_s.strip.present? }
  end

  def localized_value(hash, locale)
    hash.to_h[locale].to_s.presence
  end
end
