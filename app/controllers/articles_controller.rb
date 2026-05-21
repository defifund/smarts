# frozen_string_literal: true

class ArticlesController < ApplicationController
  allow_unauthenticated_access

  def index
    @articles = Article.published.order(published_at: :desc, slug: :desc)
  end

  def show
    @article = Article.published.find_by!(slug: params[:slug])
    requested_locale = Article.locale_from_route(params[:locale])
    @locale = @article.locale_for(requested_locale)
    raise ActiveRecord::RecordNotFound unless @locale

    @title = @article.title_for(@locale)
    @summary = @article.summary_for(@locale)
    @content = @article.content_for(@locale)
    @canonical_path = @article.public_path(@locale)
    @canonical_slug = @canonical_path.delete_prefix("/")
  rescue KeyError
    raise ActiveRecord::RecordNotFound
  end
end
