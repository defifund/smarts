# frozen_string_literal: true

class ValidateArticleDraftTool < ApplicationTool
  tool_name "validate_article_draft"
  description "Validate one multilingual article draft under docs/drafts/:slug without publishing it."

  input_schema(
    properties: {
      publish_token: { type: "string", description: "Article publishing token." },
      slug: { type: "string", description: "Two-character draft slug, lowercase letters and digits only." }
    },
    required: [ "publish_token", "slug" ]
  )

  class << self
    def payload(publish_token:, slug:)
      user = authenticate_publisher(publish_token)
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
