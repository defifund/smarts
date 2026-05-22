# frozen_string_literal: true

module Articles
  class TweetScheduler
    Result = Struct.new(:scheduled, :errors, keyword_init: true) do
      def valid?
        errors.empty?
      end

      def to_h
        {
          tweets_scheduled: scheduled,
          tweet_errors: errors
        }
      end
    end

    class << self
      def call(article:, user:, tweets:, thread: true, at: nil)
        new(article: article, user: user, tweets: tweets, thread: thread, at: at).call
      end
    end

    def initialize(article:, user:, tweets:, thread:, at: nil)
      @article = article
      @user = user
      @tweets = tweets.is_a?(Hash) ? tweets : {}
      @thread = thread
      @at = at
      @scheduled = {}
      @errors = {}
    end

    def call
      return Result.new(scheduled: {}, errors: {}) if @tweets.blank?

      @tweets.each do |locale, texts|
        schedule_locale(locale.to_s, Array(texts).map(&:to_s).map(&:strip).reject(&:blank?))
      end

      Result.new(scheduled: @scheduled, errors: @errors)
    end

    private

    def schedule_locale(locale, texts)
      return if texts.blank?

      unless Article::SUPPORTED_LOCALES.include?(locale)
        @errors[locale] = "unsupported locale"
        return
      end

      account = @user.accounts.find_by(provider: "x", locale: locale)
      unless account
        @errors[locale] = "missing x account for #{locale}"
        return
      end

      scheduler = @thread ? :thread : :tweets
      @scheduled[locale] = XQueue::Scheduler.public_send(
        scheduler,
        texts: texts,
        account: account,
        source: @article,
        **scheduling_kwargs
      )
    rescue StandardError => e
      @errors[locale] = e.message
    end

    # When the caller passed an explicit publish time, honor it as the exact
    # schedule time (XQueue's `at:`). Otherwise fall back to the article's
    # `published_at` as a floor (`not_before:`) — preserves the historical
    # behavior of appending after the account's existing queue.
    def scheduling_kwargs
      @at ? { at: @at } : { not_before: @article.published_at }
    end
  end
end
