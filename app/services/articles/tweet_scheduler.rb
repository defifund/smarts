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
      def call(article:, user:, tweets:, thread: true)
        new(article: article, user: user, tweets: tweets, thread: thread).call
      end
    end

    def initialize(article:, user:, tweets:, thread:)
      @article = article
      @user = user
      @tweets = tweets.is_a?(Hash) ? tweets : {}
      @thread = thread
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
        not_before: @article.published_at
      )
    rescue StandardError => e
      @errors[locale] = e.message
    end
  end
end
