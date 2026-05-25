require "test_helper"
require "ostruct"

class Seo::JsonLdTest < ActiveSupport::TestCase
  test "homepage emits WebSite with SearchAction" do
    data = Seo::JsonLd.homepage

    assert_equal "WebSite", data["@type"]
    assert_equal "Smarts", data["name"]
    assert_equal "https://smarts.md/", data["url"]
    assert_equal "SearchAction", data["potentialAction"]["@type"]
  end

  test "item_list emits ordered list items and optional description" do
    data = Seo::JsonLd.item_list(
      name: "Top contracts",
      description: "Canonical contract URLs",
      items: [
        { url: "https://smarts.md/usdc-eth" },
        { url: "https://smarts.md/uni-eth" }
      ]
    )

    assert_equal "ItemList", data["@type"]
    assert_equal 2, data["numberOfItems"]
    assert_equal "Canonical contract URLs", data["description"]
    assert_equal "https://smarts.md/usdc-eth", data["itemListElement"][0]["item"]
    assert_equal 1, data["itemListElement"][0]["position"]
  end

  test "contract emits WebPage with nested SoftwareApplication metadata" do
    contract = OpenStruct.new(
      name: "USD Coin",
      address: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
      compiler_version: "v0.8.20+commit.a1b79de6",
      license: "MIT"
    )
    chain = OpenStruct.new(name: "Ethereum")
    classification = OpenStruct.new(display_name: "ERC-20 Token", description: "A fungible token.")

    data = Seo::JsonLd.contract(
      contract: contract,
      chain: chain,
      classification: classification,
      display_name: "USD Coin",
      canonical_url: "https://smarts.md/usdc-eth",
      title: "USD Coin on Ethereum | smarts.md",
      description: "desc"
    )

    assert_equal "WebPage", data["@type"]
    assert_equal "https://smarts.md/usdc-eth", data["@id"]
    assert_equal "USD Coin on Ethereum | smarts.md", data["name"]
    assert_equal "USD Coin", data["about"]["name"]
    assert_equal "MIT", data["about"]["license"]
  end

  test "breadcrumb emits ordered BreadcrumbList" do
    data = Seo::JsonLd.breadcrumb([
      { name: "Smarts", url: "https://smarts.md/" },
      { name: "UNI on Ethereum", url: "https://smarts.md/uni-eth" }
    ])

    assert_equal "BreadcrumbList", data["@type"]
    assert_equal 2, data["itemListElement"].size
    assert_equal 1, data["itemListElement"][0]["position"]
    assert_equal "Smarts", data["itemListElement"][0]["name"]
  end
end
