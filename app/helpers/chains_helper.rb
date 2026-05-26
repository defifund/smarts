# frozen_string_literal: true

module ChainsHelper
  def public_chains_index_path(locale: I18n.locale, **params)
    route_locale = Article.route_locale_for(locale.to_s)
    path = route_locale.present? ? "/#{route_locale}/chains" : "/chains"
    params.present? ? "#{path}?#{params.to_query}" : path
  end

  def public_testnets_path(locale: I18n.locale, **params)
    route_locale = Article.route_locale_for(locale.to_s)
    path = route_locale.present? ? "/#{route_locale}/testnets" : "/testnets"
    params.present? ? "#{path}?#{params.to_query}" : path
  end

  def public_chain_path(slug, locale: I18n.locale)
    route_locale = Article.route_locale_for(locale.to_s)
    route_locale.present? ? "/#{route_locale}/chains/#{slug}" : "/chains/#{slug}"
  end

  def public_chain_markdown_path(slug, locale: I18n.locale)
    "#{public_chain_path(slug, locale: locale)}.md"
  end
end
