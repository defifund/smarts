require "test_helper"
require "ostruct"

class SeoHelperTest < ActionView::TestCase
  test "page_title falls back to default when nothing is set" do
    assert_equal SeoHelper::DEFAULT_TITLE, page_title
  end

  test "page_title appends site suffix to a custom title" do
    seo_meta title: "Foo"
    assert_equal "Foo | smarts.md", page_title
  end

  test "page_description falls back to default when nothing is set" do
    assert_equal SeoHelper::DEFAULT_DESC, page_description
  end

  test "page_description returns custom value when set" do
    seo_meta description: "Custom description"
    assert_equal "Custom description", page_description
  end

  test "page_og_type defaults to website" do
    assert_equal "website", page_og_type
  end

  test "render_social_meta emits required og and twitter tags" do
    seo_meta title: "Foo", description: "Bar", canonical: "https://smarts.md/foo"

    html = render_social_meta
    assert_match(/<meta name="description" content="Bar">/, html)
    assert_match(/<meta property="og:site_name" content="Smarts">/, html)
    assert_match(/<meta property="og:title" content="Foo \| smarts.md">/, html)
    assert_match(/<meta property="og:description" content="Bar">/, html)
    assert_match(/<meta property="og:url" content="https:\/\/smarts.md\/foo">/, html)
    assert_match(/<meta property="og:type" content="website">/, html)
    assert_match(/<meta property="og:image" content="https:\/\/smarts.md\/icon.png">/, html)
    assert_match(/<meta name="twitter:card" content="summary">/, html)
    assert_match(/<meta name="twitter:title" content="Foo \| smarts.md">/, html)
  end

  test "contract_json_ld emits valid schema.org WebPage with SoftwareApplication entity" do
    contract = OpenStruct.new(
      name: "USD Coin",
      address: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
    )
    chain = OpenStruct.new(name: "Ethereum", slug: "eth")
    classification = OpenStruct.new(display_name: "ERC-20 Token", description: "A fungible token.")
    seo_meta title: "USD Coin on Ethereum", description: "desc", canonical: "https://smarts.md/usdc-eth"

    html = contract_json_ld(contract: contract, chain: chain, classification: classification)

    # The helper returns a <script> tag with embedded JSON.
    assert_match(%r{<script type="application/ld\+json">}, html)

    # Strip the wrapper and verify the JSON parses and has the right shape.
    json = html.match(%r{<script[^>]*>(.+)</script>}m)[1]
    data = JSON.parse(json)

    assert_equal "https://schema.org", data["@context"]
    assert_equal "WebPage", data["@type"]
    assert_equal "https://smarts.md/usdc-eth", data["url"]
    assert_equal "USD Coin on Ethereum | smarts.md", data["name"]
    assert_equal "Smarts", data["isPartOf"]["name"]

    app = data["about"]
    assert_equal "SoftwareApplication", app["@type"]
    assert_equal "USD Coin", app["name"]
    assert_equal "SmartContract", app["applicationCategory"]
    assert_equal "Ethereum", app["operatingSystem"]
    assert_equal "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", app["identifier"]
    assert_equal "ERC-20 Token", app["additionalType"]
    assert_equal "A fungible token.", app["description"]
  end

  test "contract_json_ld omits classification fields when classification is nil" do
    contract = OpenStruct.new(name: "Thing", address: "0xabc")
    chain = OpenStruct.new(name: "Ethereum")
    seo_meta canonical: "https://smarts.md/eth/0xabc"

    html = contract_json_ld(contract: contract, chain: chain, classification: nil)
    json = html.match(%r{<script[^>]*>(.+)</script>}m)[1]
    data = JSON.parse(json)

    refute data["about"].key?("additionalType")
    refute data["about"].key?("description")
  end

  test "contract_json_ld escapes dangerous sequences that could break out of the script tag" do
    contract = OpenStruct.new(name: "Malicious </script><script>alert(1)</script>", address: "0xabc")
    chain = OpenStruct.new(name: "Ethereum")
    seo_meta canonical: "https://smarts.md/eth/0xabc"

    html = contract_json_ld(contract: contract, chain: chain, classification: nil)
    # Only one opening script tag should be present — json_escape converts `</` into `<\/`.
    assert_equal 1, html.scan("<script").size
  end
end
