# frozen_string_literal: true

module ChainsHelper
  def public_chains_index_path(locale: I18n.locale)
    route_locale = Article.route_locale_for(locale.to_s)
    route_locale.present? ? "/#{route_locale}/chains" : "/chains"
  end

  def public_chain_path(slug, locale: I18n.locale)
    route_locale = Article.route_locale_for(locale.to_s)
    route_locale.present? ? "/#{route_locale}/chains/#{slug}" : "/chains/#{slug}"
  end

  def public_chain_markdown_path(slug, locale: I18n.locale)
    "#{public_chain_path(slug, locale: locale)}.md"
  end
end
