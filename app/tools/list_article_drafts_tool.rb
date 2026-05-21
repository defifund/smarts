# frozen_string_literal: true

class ListArticleDraftsTool < ApplicationTool
  tool_name "list_article_drafts"
  description "List multilingual article drafts under docs/drafts, including slug, category, locales, and validation errors. Requires the MCP connection to carry an Authorization: Bearer <publish_token> header."

  input_schema(properties: {})

  class << self
    def payload
      user = current_publisher
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
