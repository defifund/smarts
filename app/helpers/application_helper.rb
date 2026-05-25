module ApplicationHelper
  def localized_articles_index_path(locale: I18n.locale)
    locale_key = locale.to_s
    route_locale =
      if Article::LOCALE_ROUTE_MAP.key?(locale_key)
        locale_key
      else
        Article.route_locale_for(locale_key)
      end

    route_locale.present? ? localized_articles_path(route_locale) : articles_path
  end
end
