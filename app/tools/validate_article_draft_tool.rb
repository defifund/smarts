# frozen_string_literal: true

class ValidateArticleDraftTool < ApplicationTool
  tool_name "validate_article_draft"
  description "Validate one multilingual article draft without publishing it. Pass meta and content inline to validate a local draft; omit both to read docs/drafts/:slug on the server. Requires the MCP connection to carry an Authorization: Bearer <publish_token> header."

  input_schema(
    properties: {
      slug: { type: "string", description: "Two-character draft slug, lowercase letters and digits only." },
      meta: {
        type: "object",
        description: "Article metadata: { category, subcategory, title: {locale: ...}, summary: {locale: ...} }."
      },
      content: {
        type: "object",
        description: "Locale-to-markdown mapping, e.g. {\"en\": \"# Title\\n\\nbody\", \"zh-CN\": \"...\"}."
      }
    },
    required: [ "slug" ]
  )

  class << self
    def payload(slug:, meta: nil, content: nil)
      user = current_publisher
      return user if user.is_a?(Hash)

      draft = if meta.present? || content.present?
        Articles::DraftReader.from_payload(slug: slug, meta: meta || {}, content: content || {})
      else
        Articles::DraftReader.call(slug: slug)
      end

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
