# frozen_string_literal: true

require "json"

module Articles
  class DraftReader
    Result = Struct.new(:slug, :path, :title, :summary, :content, :locales, :category, :subcategory, :errors, keyword_init: true) do
      def valid?
        errors.empty?
      end

      def to_h
        {
          slug: slug,
          path: path.to_s,
          category: category,
          subcategory: subcategory,
          locales: locales,
          title: title,
          summary: summary,
          content: content,
          errors: errors
        }
      end
    end

    class << self
      def call(slug:, drafts_root: Rails.root.join("docs/drafts"))
        new(slug: slug, drafts_root: drafts_root).call
      end

      def list(drafts_root: Rails.root.join("docs/drafts"))
        each_draft(drafts_root) { |slug, root| call(slug: slug, drafts_root: root) }
      end

      # Cheap listing: skips reading and stripping markdown bodies. Used by
      # `list_article_drafts` MCP tool which only consumes slug/category/
      # subcategory/locales/valid/errors.
      def list_summaries(drafts_root: Rails.root.join("docs/drafts"))
        each_draft(drafts_root) { |slug, root| new(slug: slug, drafts_root: root).summary }
      end

      private

      def each_draft(drafts_root)
        root = Pathname(drafts_root)
        return [] unless root.directory?

        root.children.select(&:directory?).sort_by { |path| path.basename.to_s }.map do |path|
          yield(path.basename.to_s, root)
        end
      end
    end

    def initialize(slug:, drafts_root:)
      @slug = slug.to_s.strip
      @drafts_root = Pathname(drafts_root)
      @errors = []
    end

    def call
      build_result(read_markdown_files)
    end

    def summary
      build_result(scan_locale_files)
    end

    private

    def build_result(content)
      validate_slug
      validate_path
      meta = read_meta

      category = meta["category"].to_s.strip
      subcategory = meta["subcategory"].to_s.strip.presence
      title = locale_hash(meta["title"])
      summary = locale_hash(meta["summary"])
      locales = content.keys.sort

      validate_category(category, subcategory)
      validate_locale_presence("title", title)
      validate_locale_presence("content", content)

      Result.new(
        slug: @slug,
        path: draft_path,
        title: title,
        summary: summary,
        content: content,
        locales: locales,
        category: category,
        subcategory: subcategory,
        errors: @errors
      )
    end

    def draft_path
      @drafts_root.join(@slug)
    end

    def validate_slug
      unless @slug.match?(Article::SLUG_FORMAT)
        @errors << "slug must be exactly two lowercase letters or digits"
      end
      @errors << "slug is reserved" if Article::RESERVED_SLUGS.include?(@slug)
    end

    def validate_path
      @errors << "draft directory not found: #{draft_path}" unless draft_path.directory?
    end

    def read_meta
      path = draft_path.join("meta.json")
      unless path.file?
        @errors << "meta.json not found"
        return {}
      end

      JSON.parse(path.read)
    rescue JSON::ParserError => e
      @errors << "meta.json is invalid JSON: #{e.message}"
      {}
    end

    def read_markdown_files
      each_markdown_file do |path, locale, hash|
        body = strip_first_heading(path.read)
        @errors << "#{path.basename} has empty content" if body.blank?
        hash[locale] = body
      end
    end

    # Like `read_markdown_files` but skips reading the body — only records
    # which locales are present, and reports emptiness via cheap stat. The
    # placeholder value satisfies `validate_locale_presence` without paying
    # the cost of reading and heading-stripping each file.
    def scan_locale_files
      each_markdown_file do |path, locale, hash|
        empty = path.size.zero?
        @errors << "#{path.basename} has empty content" if empty
        hash[locale] = empty ? "" : "present"
      end
    end

    def each_markdown_file
      return {} unless draft_path.directory?

      draft_path.children.select { |path| path.file? && path.extname == ".md" }.each_with_object({}) do |path, hash|
        locale = path.basename(".md").to_s
        unless Article::SUPPORTED_LOCALES.include?(locale)
          @errors << "unsupported locale file: #{path.basename}"
          next
        end

        yield(path, locale, hash)
      end
    end

    def strip_first_heading(markdown)
      lines = markdown.to_s.lines
      lines.shift if lines.first&.match?(/\A#\s+/)
      lines.join.strip
    end

    def locale_hash(value)
      return {} unless value.is_a?(Hash)

      value.each_with_object({}) do |(locale, text), hash|
        locale = locale.to_s
        if Article::SUPPORTED_LOCALES.include?(locale)
          hash[locale] = text.to_s.strip
        else
          @errors << "unsupported locale in meta: #{locale}"
        end
      end
    end

    def validate_category(category, subcategory)
      @errors << "category is required" if category.blank?
      @errors << "category is unsupported: #{category}" if category.present? && !Article::CATEGORIES.include?(category)
      return if subcategory.blank?
      return if Article::SUBCATEGORIES.fetch(category, []).include?(subcategory)

      @errors << "subcategory #{subcategory} is not allowed for #{category}"
    end

    def validate_locale_presence(field, value)
      return if Article::SUPPORTED_LOCALES.any? { |locale| value[locale].to_s.strip.present? }

      @errors << "#{field} must include at least one supported locale"
    end
  end
end
