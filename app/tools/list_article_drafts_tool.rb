# frozen_string_literal: true

class ListArticleDraftsTool < ApplicationTool
  tool_name "list_article_drafts"
  description "List multilingual article drafts under docs/drafts, including slug, category, locales, and validation errors."

  input_schema(
    properties: {
      publish_token: { type: "string", description: "Article publishing token." }
    },
    required: [ "publish_token" ]
  )

  class << self
    def payload(publish_token:)
      user = authenticate_publisher(publish_token)
      return user if user.is_a?(Hash)

      drafts = Articles::DraftReader.list_summaries

      {
        count: drafts.length,
        drafts: drafts.map do |draft|
          {
            slug: draft.slug,
            category: draft.category,
            subcategory: draft.subcategory,
            locales: draft.locales,
            valid: draft.valid?,
            errors: draft.errors
          }
        end
      }
    end
  end
end
