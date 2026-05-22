# frozen_string_literal: true

module Articles
  class Publisher
    Result = Struct.new(:article, :draft, :urls, :errors, :dry_run, :tweets_scheduled, :tweet_errors, keyword_init: true) do
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
          errors: errors,
          tweets_scheduled: tweets_scheduled || {},
          tweet_errors: tweet_errors || {}
        }
      end
    end

    class << self
      def call(slug:, user:, drafts_root: Rails.root.join("docs/drafts"), meta: nil, content: nil, published_at: nil, dry_run: false, tweets: {}, thread: true)
        new(slug: slug, user: user, drafts_root: drafts_root, meta: meta, content: content, published_at: published_at, dry_run: dry_run, tweets: tweets, thread: thread).call
      end
    end

    def initialize(slug:, user:, drafts_root:, meta:, content:, published_at:, dry_run:, tweets:, thread:)
      @slug = slug
      @user = user
      @drafts_root = drafts_root
      @meta = meta
      @content = content
      @explicit_published_at = published_at
      @published_at = published_at || Time.current
      @dry_run = dry_run
      @tweets = tweets.is_a?(Hash) ? tweets : {}
      @thread = thread
    end

    def call
      draft = read_draft
      return Result.new(draft: draft, urls: {}, errors: draft.errors, dry_run: @dry_run, tweets_scheduled: {}, tweet_errors: {}) unless draft.valid?

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
        return Result.new(article: article, draft: draft, urls: {}, errors: article.errors.full_messages, dry_run: @dry_run, tweets_scheduled: {}, tweet_errors: {})
      end

      article.save! unless @dry_run

      tweet_result = schedule_tweets(article)
      Result.new(
        article: article,
        draft: draft,
        urls: urls_for(article, draft.locales),
        errors: [],
        dry_run: @dry_run,
        tweets_scheduled: tweet_result.scheduled,
        tweet_errors: tweet_result.errors
      )
    end

    private

    def read_draft
      if @meta.present? || @content.present?
        DraftReader.from_payload(slug: @slug, meta: @meta || {}, content: @content || {})
      else
        DraftReader.call(slug: @slug, drafts_root: @drafts_root)
      end
    end

    def urls_for(article, locales)
      locales.index_with { |locale| "#{SeoHelper::SITE_URL}#{article.public_path(locale)}" }
    end

    def schedule_tweets(article)
      return TweetScheduler::Result.new(scheduled: {}, errors: {}) if @dry_run || @tweets.blank?

      TweetScheduler.call(
        article: article,
        user: @user,
        tweets: @tweets,
        thread: @thread,
        at: @explicit_published_at
      )
    end
  end
end
