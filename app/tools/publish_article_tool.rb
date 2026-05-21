# frozen_string_literal: true

class PublishArticleTool < ApplicationTool
  tool_name "publish_article"
  description "Publish a validated multilingual article draft from docs/drafts/:slug into Smarts article pages. Optionally schedule X posts via x_queue. Requires the MCP connection to carry an Authorization: Bearer <publish_token> header."

  input_schema(
    properties: {
      slug: { type: "string", description: "Two-character draft slug, lowercase letters and digits only." },
      published_at: { type: "string", description: "Optional ISO-8601 publish time. Defaults to now." },
      dry_run: { type: "boolean", description: "Validate and return URLs without saving. Defaults to false." },
      thread: { type: "boolean", description: "When tweets are provided, schedule each locale as a thread. Defaults to true." },
      tweets: {
        type: "object",
        description: "Optional locale-to-array mapping of X posts, e.g. {\"zh-CN\":[\"tweet 1\", \"tweet 2\"]}."
      }
    },
    required: [ "slug" ]
  )

  class << self
    def payload(slug:, published_at: nil, dry_run: false, thread: true, tweets: {})
      user = current_publisher
      return user if user.is_a?(Hash)

      Articles::Publisher.call(
        slug: slug,
        user: user,
        published_at: parse_published_at(published_at),
        dry_run: dry_run,
        thread: thread,
        tweets: tweets || {}
      ).to_h
    rescue ActiveRecord::RecordInvalid => e
      { slug: slug, valid: false, errors: e.record.errors.full_messages }
    rescue ArgumentError => e
      { slug: slug, valid: false, errors: [ e.message ] }
    end

    private

    def parse_published_at(value)
      return Time.current if value.blank?

      Time.zone.parse(value.to_s) || raise(ArgumentError, "published_at is invalid")
    end
  end
end
