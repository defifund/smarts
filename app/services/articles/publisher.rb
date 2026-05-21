# frozen_string_literal: true

module Articles
  class Publisher
    Result = Struct.new(:article, :draft, :urls, :errors, :dry_run, keyword_init: true) do
      def valid?
        errors.empty?
      end

      def to_h
        {
          slug: draft.slug,
          dry_run: dry_run,
          valid: valid?,
          category: draft.category,
          subcategory: draft.subcategory,
          locales: draft.locales,
          urls: urls,
          errors: errors
        }
      end
    end

    class << self
      def call(slug:, user:, drafts_root: Rails.root.join("docs/drafts"), published_at: Time.current, dry_run: false)
        new(slug: slug, user: user, drafts_root: drafts_root, published_at: published_at, dry_run: dry_run).call
      end
    end

    def initialize(slug:, user:, drafts_root:, published_at:, dry_run:)
      @slug = slug
      @user = user
      @drafts_root = drafts_root
      @published_at = published_at
      @dry_run = dry_run
    end

    def call
      draft = DraftReader.call(slug: @slug, drafts_root: @drafts_root)
      return Result.new(draft: draft, urls: {}, errors: draft.errors, dry_run: @dry_run) unless draft.valid?

      article = Article.find_or_initialize_by(slug: draft.slug)
      article.assign_attributes(
        category: draft.category,
        subcategory: draft.subcategory,
        title: draft.title,
        summary: draft.summary,
        content: draft.content,
        user: @user,
        published_at: @published_at
      )

      unless article.valid?
        return Result.new(article: article, draft: draft, urls: {}, errors: article.errors.full_messages, dry_run: @dry_run)
      end

      article.save! unless @dry_run
      Result.new(article: article, draft: draft, urls: urls_for(article, draft.locales), errors: [], dry_run: @dry_run)
    end

    private

    def urls_for(article, locales)
      locales.index_with { |locale| "#{SeoHelper::SITE_URL}#{article.public_path(locale)}" }
    end
  end
end
