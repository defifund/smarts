# frozen_string_literal: true

class PublishArticleTool < ApplicationTool
  tool_name "publish_article"
  description "Publish a validated multilingual article draft from docs/drafts/:slug into Smarts article pages. Supports dry_run validation."

  input_schema(
    properties: {
      publish_token: { type: "string", description: "Article publishing token." },
      slug: { type: "string", description: "Two-character draft slug, lowercase letters and digits only." },
      dry_run: { type: "boolean", description: "Validate and return URLs without saving. Defaults to false." }
    },
    required: [ "publish_token", "slug" ]
  )

  class << self
    def payload(publish_token:, slug:, dry_run: false)
      user = authenticate_publisher(publish_token)
      return user if user.is_a?(Hash)

      Articles::Publisher.call(slug: slug, user: user, dry_run: dry_run).to_h
    rescue ActiveRecord::RecordInvalid => e
      { slug: slug, valid: false, errors: e.record.errors.full_messages }
    end
  end
end
