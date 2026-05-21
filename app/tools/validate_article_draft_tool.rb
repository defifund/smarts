# frozen_string_literal: true

class ValidateArticleDraftTool < ApplicationTool
  tool_name "validate_article_draft"
  description "Validate one multilingual article draft under docs/drafts/:slug without publishing it. Requires the MCP connection to carry an Authorization: Bearer <publish_token> header."

  input_schema(
    properties: {
      slug: { type: "string", description: "Two-character draft slug, lowercase letters and digits only." }
    },
    required: [ "slug" ]
  )

  class << self
    def payload(slug:)
      user = current_publisher
      return user if user.is_a?(Hash)

      draft = Articles::DraftReader.call(slug: slug)

      {
        slug: draft.slug,
        valid: draft.valid?,
        category: draft.category,
        subcategory: draft.subcategory,
        locales: draft.locales,
        path: draft.path.to_s,
        errors: draft.errors
      }
    end
  end
end
