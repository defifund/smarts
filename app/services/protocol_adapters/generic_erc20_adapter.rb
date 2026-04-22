require "bigdecimal"
require "bigdecimal/util"
require "set"

module ProtocolAdapters
  class GenericErc20Adapter < Base
    # 4-byte selectors for the 6 required ERC-20 functions.
    # totalSupply, balanceOf, transfer, transferFrom, approve, allowance.
    ERC20_REQUIRED_SELECTORS = %w[
      0x18160ddd 0x70a08231 0xa9059cbb 0x23b872dd 0x095ea7b3 0xdd62ed3e
    ].freeze

    ERC20_NAME         = { "name" => "name",        "inputs" => [], "outputs" => [ { "type" => "string" } ] }.freeze
    ERC20_SYMBOL       = { "name" => "symbol",      "inputs" => [], "outputs" => [ { "type" => "string" } ] }.freeze
    ERC20_DECIMALS     = { "name" => "decimals",    "inputs" => [], "outputs" => [ { "type" => "uint8" } ] }.freeze
    ERC20_TOTAL_SUPPLY = { "name" => "totalSupply", "inputs" => [], "outputs" => [ { "type" => "uint256" } ] }.freeze

    # Issuer whitelist keyed by chain slug → lowercase address.
    # Keep intentionally small (MVP: mainnet majors). Extend as warranted.
    ISSUERS = {
      "eth" => {
        "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48" => { name: "Circle",        url: "https://www.circle.com/" },
        "0xdac17f958d2ee523a2206206994597c13d831ec7" => { name: "Tether",        url: "https://tether.to/" },
        "0x6b175474e89094c44da98b954eedeac495271d0f" => { name: "MakerDAO",      url: "https://makerdao.com/" },
        "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2" => { name: "Wrapped Ether", url: nil },
        "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599" => { name: "BitGo (WBTC)",  url: "https://wbtc.network/" }
      }
    }.freeze

    def self.type_tag
      "generic_erc20"
    end

    def self.matches?(contract)
      selectors = contract_selectors(contract)
      return false if selectors.empty?

      ERC20_REQUIRED_SELECTORS.all? { |s| selectors.include?(s) }
    end

    def self.contract_selectors(contract)
      return Set.new unless contract.abi.is_a?(Array)

      contract.abi
        .select { |item| item["type"] == "function" }
        .map { |fn| ChainReader::Base.selector(ChainReader::Base.function_signature(fn)) }
        .map(&:downcase)
        .to_set
    end

    def protocol_name
      "ERC-20 Token"
    end

    def panel_data
      Rails.cache.fetch(cache_key, expires_in: 60.seconds) { read_panel_data }
    end

    private

    def cache_key
      "protocol_panel:generic_erc20:#{chain.slug}:#{contract.address}"
    end

    def read_panel_data
      token = read_token_metadata
      return { error: "could not read token metadata" } if token[:symbol].blank? || token[:decimals].nil?

      price = fetch_price
      market_cap = compute_market_cap(token[:total_supply], token[:decimals], price)

      {
        name: token[:name],
        symbol: token[:symbol],
        decimals: token[:decimals],
        total_supply_raw: token[:total_supply],
        total_supply_formatted: format_supply(token[:total_supply], token[:decimals], token[:symbol]),
        price_usd: price,
        market_cap_usd: market_cap,
        issuer: lookup_issuer
      }
    end

    def read_token_metadata
      calls = [
        ChainReader::Multicall3Client::Call.new(target: contract.address, function: ERC20_NAME),
        ChainReader::Multicall3Client::Call.new(target: contract.address, function: ERC20_SYMBOL),
        ChainReader::Multicall3Client::Call.new(target: contract.address, function: ERC20_DECIMALS),
        ChainReader::Multicall3Client::Call.new(target: contract.address, function: ERC20_TOTAL_SUPPLY)
      ]
      r = ChainReader::Multicall3Client.call(chain: chain, calls: calls)

      {
        name:         r[0].success ? r[0].values.first : nil,
        symbol:       r[1].success ? r[1].values.first : nil,
        decimals:     r[2].success ? r[2].values.first : nil,
        total_supply: r[3].success ? r[3].values.first : nil
      }
    rescue StandardError => e
      Rails.logger.warn("[GenericErc20Adapter] metadata read failed: #{e.class}: #{e.message}")
      { name: nil, symbol: nil, decimals: nil, total_supply: nil }
    end

    def fetch_price
      prices = DefiLlamaClient.fetch_prices(chain: chain, addresses: [ contract.address ])
      prices.dig(contract.address.downcase, "price")
    rescue DefiLlamaClient::Error => e
      Rails.logger.warn("[GenericErc20Adapter] price fetch failed: #{e.message}")
      nil
    end

    def compute_market_cap(total_supply, decimals, price)
      return nil unless total_supply && decimals && price

      (total_supply.to_f / (10.0**decimals.to_i) * price).round(2)
    end

    def format_supply(raw, decimals, symbol)
      return nil unless raw.is_a?(Integer) && decimals

      scaled = (raw.to_d / (BigDecimal(10) ** decimals.to_i)).round(2, BigDecimal::ROUND_DOWN)
      whole, frac = scaled.to_s("F").split(".")
      whole_fmt = whole.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
      frac_padded = (frac.to_s + "00")[0, 2]
      body = frac_padded == "00" ? whole_fmt : "#{whole_fmt}.#{frac_padded}"
      symbol.present? ? "#{body} #{symbol}" : body
    end

    def lookup_issuer
      ISSUERS.dig(chain.slug, contract.address.downcase)
    end
  end
end
