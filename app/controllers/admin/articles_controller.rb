# frozen_string_literal: true

module Admin
  class ArticlesController < ApplicationController
    before_action :require_admin
    before_action :set_article, only: %i[edit update]

    def index
      @articles = Article.order(Arel.sql("published_at IS NULL DESC"), published_at: :desc, updated_at: :desc)
    end

    def edit
    end

    def update
      @article.assign_attributes(article_attributes)
      return render(:edit, status: :unprocessable_entity) unless apply_publication_status

      if @article.save
        redirect_to admin_articles_path, notice: "Article updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_article
      @article = Article.find(params[:id])
    end

    def article_params
      params.require(:article).permit(
        :slug,
        :category,
        :subcategory,
        :publication_status,
        :published_at,
        title: Article::SUPPORTED_LOCALES,
        summary: Article::SUPPORTED_LOCALES,
        content: Article::SUPPORTED_LOCALES
      )
    end

    def article_attributes
      article_params.except(:publication_status, :published_at)
    end

    def apply_publication_status
      case article_params[:publication_status]
      when "draft"
        @article.published_at = nil
      when "scheduled"
        @article.published_at = parsed_published_at
      when "published"
        @article.published_at = parsed_published_at || Time.current
      end

      @article.errors.none?
    end

    def parsed_published_at
      value = article_params[:published_at].to_s.strip
      return nil if value.blank?

      Time.zone.parse(value)
    rescue ArgumentError, TypeError
      @article.errors.add(:published_at, "is invalid")
      nil
    end

    def require_admin
      redirect_to root_path, alert: "Admin access required." unless Current.user&.admin?
    end
  end
end
