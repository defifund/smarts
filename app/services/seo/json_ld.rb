# frozen_string_literal: true

module Seo
  class JsonLd
    class << self
      def homepage
        {
          "@context" => "https://schema.org",
          "@type"    => "WebSite",
          "name"     => SeoHelper::SITE_NAME,
          "url"      => "#{SeoHelper::SITE_URL}/",
          "potentialAction" => {
            "@type"       => "SearchAction",
            "target"      => { "@type" => "EntryPoint", "urlTemplate" => "#{SeoHelper::SITE_URL}/?q={search_term_string}" },
            "query-input" => "required name=search_term_string"
          }
        }
      end

      def item_list(name:, items:, description: nil)
        data = {
          "@context"        => "https://schema.org",
          "@type"           => "ItemList",
          "name"            => name,
          "itemListOrder"   => "https://schema.org/ItemListOrderAscending",
          "numberOfItems"   => items.length,
          "itemListElement" => items.each_with_index.map do |item, index|
            list_item = {
              "@type"    => "ListItem",
              "position" => index + 1
            }

            list_item["name"] = item[:name] if item[:name].present?
            list_item["item"] = item[:url] if item[:url].present?
            list_item["url"] = item[:url] if item[:url].present?
            list_item
          end
        }
        data["description"] = description if description.present?
        data
      end

      def contract(contract:, chain:, classification: nil, display_name: nil, canonical_url: nil, title: nil, description: nil)
        app = {
          "@type"               => "SoftwareApplication",
          "name"                => display_name.presence || contract.name.presence || "Unknown Contract",
          "applicationCategory" => "SmartContract",
          "operatingSystem"     => chain.name,
          "identifier"          => contract.address
        }
        app["additionalType"]  = classification.display_name if classification&.display_name.present?
        app["description"]     = classification.description  if classification&.description.present?
        app["softwareVersion"] = contract.compiler_version   if contract.compiler_version.present?
        app["license"]         = contract.license            if contract.license.present?

        {
          "@context"    => "https://schema.org",
          "@type"       => "WebPage",
          "@id"         => canonical_url,
          "url"         => canonical_url,
          "name"        => title,
          "description" => description,
          "isPartOf"    => { "@type" => "WebSite", "name" => SeoHelper::SITE_NAME, "url" => SeoHelper::SITE_URL },
          "about"       => app
        }
      end

      def breadcrumb(items)
        {
          "@context"        => "https://schema.org",
          "@type"           => "BreadcrumbList",
          "itemListElement" => items.each_with_index.map do |item, i|
            { "@type" => "ListItem", "position" => i + 1, "name" => item[:name], "item" => item[:url] }
          end
        }
      end
    end
  end
end
