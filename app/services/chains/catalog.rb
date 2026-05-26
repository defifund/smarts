# frozen_string_literal: true

module Chains
  module Catalog
    Contract = Struct.new(
      :chain_slug,
      :name,
      :slug,
      :address,
      :kind,
      :notes,
      keyword_init: true
    ) do
      def path(locale: I18n.locale)
        route_locale = Article.route_locale_for(locale.to_s)
        base_path = slug.present? ? "/#{slug}" : "/#{chain_slug}/#{address}"
        route_locale.present? ? "/#{route_locale}#{base_path}" : base_path
      end
    end

    Chain = Struct.new(
      :slug,
      :name,
      :chain_id,
      :tier,
      :network_kind,
      :summary,
      :docs_url,
      :explorer_url,
      :faucet_url,
      :verify_url,
      :contracts,
      keyword_init: true
    ) do
      def full?
        tier.to_s == "full"
      end

      def docs_only?
        tier.to_s == "docs_only"
      end

      def mainnet?
        network_kind.to_s == "mainnet"
      end

      def testnet?
        network_kind.to_s == "testnet"
      end

      def contract_count
        contracts.length
      end

      def slugged_contract_count
        contracts.count { |contract| contract.slug.present? }
      end

      def kind_counts
        contracts.group_by(&:kind).transform_values(&:length)
      end

      def top_kinds(limit = 2)
        kind_counts.sort_by { |kind, count| [ -count, kind ] }.first(limit)
      end

      def path(locale: I18n.locale)
        route_locale = Article.route_locale_for(locale.to_s)
        route_locale.present? ? "/#{route_locale}/chains/#{slug}" : "/chains/#{slug}"
      end
    end

    class << self
      def all
        DISPLAY_ORDER.map { |slug| CHAINS.fetch(slug) }
      end

      def fetch(slug)
        CHAINS.fetch(slug)
      end

      def contract(chain_slug, name:, address:, kind:, slug: nil, notes: nil)
        Contract.new(
          chain_slug: chain_slug,
          name: name,
          slug: slug,
          address: address.downcase,
          kind: kind,
          notes: notes
        )
      end

      def slug_contract(slug, name:, kind:, notes: nil)
        chain_slug, address = ContractSlugs.resolve(slug)
        contract(chain_slug, name: name, slug: slug, address: address, kind: kind, notes: notes)
      end

      def chain(
        slug,
        name:,
        chain_id:,
        tier:,
        summary:,
        docs_url: nil,
        explorer_url: nil,
        faucet_url: nil,
        verify_url: nil,
        network_kind: "mainnet",
        contracts: []
      )
        Chain.new(
          slug: slug,
          name: name,
          chain_id: chain_id,
          tier: tier,
          network_kind: network_kind,
          summary: summary,
          docs_url: docs_url,
          explorer_url: explorer_url,
          faucet_url: faucet_url,
          verify_url: verify_url,
          contracts: contracts
        )
      end
    end

    DISPLAY_ORDER = ::Chain::DISPLAY_ORDER

    CHAINS = [
      chain(
        "eth",
        name: "Ethereum",
        chain_id: 1,
        tier: "full",
        summary: "Blue-chip Ethereum contracts for stablecoins, DeFi, and core protocol plumbing.",
        contracts: [
          slug_contract("usdc-eth", name: "USD Coin", kind: "Token"),
          slug_contract("usdt-eth", name: "Tether USD", kind: "Token"),
          slug_contract("dai-eth", name: "Dai", kind: "Token"),
          slug_contract("uni-eth", name: "Uniswap", kind: "Governance"),
          slug_contract("aave-eth", name: "Aave", kind: "Governance"),
          slug_contract("link-eth", name: "Chainlink", kind: "Oracle"),
          slug_contract("weth-eth", name: "Wrapped Ether", kind: "Token"),
          slug_contract("wbtc-eth", name: "Wrapped Bitcoin", kind: "Token")
        ]
      ),
      chain(
        "base",
        name: "Base",
        chain_id: 8453,
        tier: "full",
        summary: "Base-native stablecoin, DEX, and lending contracts built on the OP Stack.",
        contracts: [
          slug_contract("usdc-base", name: "USD Coin", kind: "Token"),
          slug_contract("aero-base", name: "Aerodrome", kind: "DEX"),
          slug_contract("aavev3-pool-base", name: "Aave V3 Pool", kind: "Lending"),
          contract("base", name: "Wrapped Ether", address: "0x4200000000000000000000000000000000000006", kind: "Token"),
          contract("base", name: "Base USDC Bridge", address: "0x4200000000000000000000000000000000000010", kind: "Bridge")
        ]
      ),
      chain(
        "arbitrum",
        name: "Arbitrum One",
        chain_id: 42161,
        tier: "full",
        summary: "Native stablecoin and lending contracts on Arbitrum One.",
        contracts: [
          slug_contract("usdc-arbitrum", name: "USD Coin", kind: "Token"),
          slug_contract("usdt-arbitrum", name: "Tether USD", kind: "Token"),
          slug_contract("arb-arbitrum", name: "Arbitrum", kind: "Governance"),
          slug_contract("aavev3-pool-arbitrum", name: "Aave V3 Pool", kind: "Lending"),
          contract("arbitrum", name: "Wrapped Ether", address: "0x82af49447d8a07e3bd95bd0d56f35241523fbab1", kind: "Token"),
          contract("arbitrum", name: "Wrapped Bitcoin", address: "0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f", kind: "Token")
        ]
      ),
      chain(
        "optimism",
        name: "Optimism",
        chain_id: 10,
        tier: "full",
        summary: "Optimism-native stablecoins, governance tokens, and lending markets.",
        contracts: [
          slug_contract("usdc-optimism", name: "USD Coin", kind: "Token"),
          slug_contract("usdt-optimism", name: "Tether USD", kind: "Token"),
          slug_contract("op-optimism", name: "Optimism", kind: "Governance"),
          slug_contract("aavev3-pool-optimism", name: "Aave V3 Pool", kind: "Lending"),
          contract("optimism", name: "Wrapped Ether", address: "0x4200000000000000000000000000000000000006", kind: "Token"),
          contract("optimism", name: "Wrapped Bitcoin", address: "0x68f180fcce6836688e9084f035309e29bf0a2095", kind: "Token")
        ]
      ),
      chain(
        "bnb",
        name: "BNB Smart Chain",
        chain_id: 56,
        tier: "full",
        summary: "The biggest BNB Chain primitives: stablecoins, wrapped gas, and PancakeSwap.",
        contracts: [
          slug_contract("usdt-bnb", name: "Tether USD", kind: "Token"),
          slug_contract("wbnb-bnb", name: "Wrapped BNB", kind: "Token"),
          slug_contract("cake-bnb", name: "PancakeSwap", kind: "Governance"),
          contract("bnb", name: "USD Coin", address: "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d", kind: "Token"),
          contract("bnb", name: "BUSD", address: "0xe9e7cea3dedca5984780bafc599bd69add087d56", kind: "Token")
        ]
      ),
      chain(
        "polygon",
        name: "Polygon PoS",
        chain_id: 137,
        tier: "full",
        summary: "Polygon's canonical stablecoins, wrapped gas token, and Polymarket infrastructure.",
        contracts: [
          slug_contract("usdc-polygon", name: "USD Coin", kind: "Token"),
          slug_contract("usdt-polygon", name: "Tether USD", kind: "Token"),
          slug_contract("wpol-polygon", name: "Wrapped POL", kind: "Token"),
          slug_contract("aavev3-pool-polygon", name: "Aave V3 Pool", kind: "Lending"),
          slug_contract("polymarket-ctf-exchange-v2-polygon", name: "Polymarket CTF Exchange V2", kind: "Exchange"),
          slug_contract("polymarket-neg-risk-exchange-v2-polygon", name: "Polymarket Neg-Risk Exchange V2", kind: "Exchange"),
          slug_contract("polymarket-uma-adapter-v3-polygon", name: "Polymarket UMA Adapter V3", kind: "Oracle"),
          slug_contract("polymarket-conditional-tokens-polygon", name: "Conditional Tokens", kind: "Resolution")
        ]
      ),
      chain(
        "sepolia",
        name: "Ethereum Sepolia",
        chain_id: 11_155_111,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "Ethereum Sepolia testnet contracts and explorer-supported tooling.",
        docs_url: "https://ethereum.org/developers/docs/networks/",
        explorer_url: "https://sepolia.etherscan.io",
        faucet_url: "https://www.alchemy.com/faucets/ethereum-sepolia",
        verify_url: "https://sepolia.etherscan.io/verifyContract"
      ),
      chain(
        "hoodi",
        name: "Ethereum Hoodi",
        chain_id: 560_048,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "Ethereum Hoodi testnet contracts and explorer-supported tooling.",
        docs_url: "https://hoodi.ethpandaops.io/",
        explorer_url: "https://hoodi.etherscan.io",
        faucet_url: "https://faucet.hoodi.ethpandaops.io/",
        verify_url: "https://hoodi.etherscan.io/verifyContract"
      ),
      chain(
        "polygon-amoy",
        name: "Polygon Amoy",
        chain_id: 80_002,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "Polygon Amoy testnet contracts and explorer-supported tooling.",
        docs_url: "https://docs.polygon.technology/pos/reference/rpc-endpoints/",
        explorer_url: "https://amoy.polygonscan.com",
        faucet_url: "https://faucet.polygon.technology/",
        verify_url: "https://amoy.polygonscan.com/verifyContract"
      ),
      chain(
        "arbitrum-sepolia",
        name: "Arbitrum Sepolia",
        chain_id: 421_614,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "Arbitrum Sepolia testnet contracts and explorer-supported tooling.",
        docs_url: "https://docs.arbitrum.io/",
        explorer_url: "https://sepolia.arbiscan.io",
        faucet_url: "https://www.alchemy.com/faucets/arbitrum-sepolia",
        verify_url: "https://sepolia.arbiscan.io/verifyContract"
      ),
      chain(
        "linea-sepolia",
        name: "Linea Sepolia",
        chain_id: 59_141,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "Linea Sepolia testnet contracts and explorer-supported tooling.",
        docs_url: "https://docs.linea.build/",
        explorer_url: "https://sepolia.lineascan.build",
        verify_url: "https://sepolia.lineascan.build/verifyContract"
      ),
      chain(
        "blast-sepolia",
        name: "Blast Sepolia",
        chain_id: 168_587_773,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "Blast Sepolia testnet contracts and explorer-supported tooling.",
        docs_url: "https://docs.blast.io/building/network-information",
        explorer_url: "https://sepolia.blastscan.io",
        faucet_url: "https://docs.blast.io/tools/faucets",
        verify_url: "https://sepolia.blastscan.io/verifyContract"
      ),
      chain(
        "celo-sepolia",
        name: "Celo Sepolia",
        chain_id: 11_142_220,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "Celo Sepolia testnet contracts and explorer-supported tooling.",
        docs_url: "https://docs.celo.org/learn/topology-of-a-celo-network",
        explorer_url: "https://celo-sepolia.blockscout.com",
        faucet_url: "https://faucet.celo.org/celo-sepolia",
        verify_url: "https://celo-sepolia.blockscout.com/verifyContract"
      ),
      chain(
        "fraxtal-hoodi",
        name: "Fraxtal Hoodi",
        chain_id: 2_523,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "Fraxtal Hoodi testnet contracts and explorer-supported tooling.",
        docs_url: "https://docs.frax.com/fraxtal/network/network-information",
        explorer_url: "https://hoodi.fraxscan.com",
        faucet_url: "https://docs.frax.com/fraxtal/tools/faucets"
      ),
      chain(
        "moonbeam",
        name: "Moonbeam",
        chain_id: 1_284,
        tier: "docs_only",
        network_kind: "mainnet",
        summary: "Moonbeam contracts surfaced from ecosystem docs and explorer pages."
      ),
      chain(
        "moonriver",
        name: "Moonriver",
        chain_id: 1_285,
        tier: "docs_only",
        network_kind: "mainnet",
        summary: "Moonriver contracts surfaced from ecosystem docs and explorer pages."
      ),
      chain(
        "moonbase",
        name: "Moonbase Alpha",
        chain_id: 1_287,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "Moonbase Alpha testnet contracts and explorer-supported tooling.",
        docs_url: "https://docs.moonbeam.network/builders/get-started/networks/moonbase/",
        explorer_url: "https://moonbase.moonscan.io"
      ),
      chain(
        "opbnb",
        name: "opBNB",
        chain_id: 204,
        tier: "docs_only",
        network_kind: "mainnet",
        summary: "opBNB contracts surfaced from ecosystem docs and explorer pages."
      ),
      chain(
        "opbnb-testnet",
        name: "opBNB Testnet",
        chain_id: 5_611,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "opBNB Testnet contracts and explorer-supported tooling.",
        docs_url: "https://docs.bnbchain.org/bnb-opbnb/get-started/network-info/",
        explorer_url: "https://testnet.opbnbscan.com",
        faucet_url: "https://docs.bnbchain.org/bnb-opbnb/developers/network-faucet/",
        verify_url: "https://docs.bnbchain.org/bnb-opbnb/advanced/verify-on-opbnbscan/"
      ),
      chain(
        "xdc",
        name: "XDC Mainnet",
        chain_id: 50,
        tier: "docs_only",
        network_kind: "mainnet",
        summary: "XDC Mainnet contracts surfaced from ecosystem docs and explorer pages."
      ),
      chain(
        "xdc-apothem",
        name: "XDC Apothem",
        chain_id: 51,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "XDC Apothem testnet contracts and explorer-supported tooling.",
        docs_url: "https://docs.xdc.network/xdcchain/developers/apothemrpc/",
        explorer_url: "https://testnet.xdcscan.com"
      ),
      chain(
        "unichain-sepolia",
        name: "Unichain Sepolia",
        chain_id: 1_301,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "Unichain Sepolia testnet contracts and explorer-supported tooling.",
        docs_url: "https://docs.unichain.org/docs/technical-information/network-information",
        explorer_url: "https://sepolia.uniscan.xyz",
        faucet_url: "https://docs.unichain.org/docs/tools/faucets",
        verify_url: "https://docs.unichain.org/docs/building-on-unichain/deploy-a-smart-contract"
      ),
      chain(
        "world-sepolia",
        name: "World Chain Sepolia",
        chain_id: 4_801,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "World Chain Sepolia testnet contracts and explorer-supported tooling.",
        docs_url: "https://docs.world.org/world-chain/quick-start/info",
        explorer_url: "https://worldchain-sepolia.explorer.alchemy.com",
        faucet_url: "https://www.alchemy.com/faucets/world-chain-sepolia",
        verify_url: "https://docs.world.org/world-chain/developers/deploy"
      ),
      chain(
        "berachain-bepolia",
        name: "Berachain Bepolia",
        chain_id: 80_069,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "Berachain Bepolia testnet contracts and explorer-supported tooling.",
        docs_url: "https://docs.berachain.com/build/getting-started/common-resources",
        explorer_url: "https://testnet.berascan.com",
        faucet_url: "https://bepolia.hub.berachain.com",
        verify_url: "https://docs.berachain.com/build/guides/verifying-smart-contracts"
      ),
      chain(
        "monad",
        name: "Monad",
        chain_id: 143,
        tier: "docs_only",
        network_kind: "mainnet",
        summary: "Monad contracts surfaced from ecosystem docs and explorer pages.",
        docs_url: "https://docs.monad.xyz/"
      ),
      chain(
        "monad-testnet",
        name: "Monad Testnet",
        chain_id: 10_143,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "Monad Testnet contracts and explorer-supported tooling.",
        docs_url: "https://docs.monad.xyz/",
        explorer_url: "https://testnet.monadvision.com",
        faucet_url: "https://faucet.monad.xyz/",
        verify_url: "https://docs.monad.xyz/"
      ),
      chain(
        "hyperevm",
        name: "HyperEVM",
        chain_id: 999,
        tier: "docs_only",
        network_kind: "mainnet",
        summary: "HyperEVM contracts surfaced from ecosystem docs and explorer pages.",
        docs_url: "https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/hyperevm",
        explorer_url: "https://hyperscan.com"
      ),
      chain(
        "hyperevm-testnet",
        name: "HyperEVM Testnet",
        chain_id: 998,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "HyperEVM Testnet contracts and explorer-supported tooling.",
        docs_url: "https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/hyperevm",
        explorer_url: "https://hyperscan.com",
        faucet_url: "https://app.hyperliquid-testnet.xyz/drip"
      ),
      chain(
        "katana",
        name: "Katana",
        chain_id: 747_474,
        tier: "docs_only",
        network_kind: "mainnet",
        summary: "Katana contracts surfaced from ecosystem docs and explorer pages.",
        docs_url: "https://docs.katana.network/katana/technical-reference/network-information/"
      ),
      chain(
        "bokuto",
        name: "Katana Bokuto",
        chain_id: 737_373,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "Katana Bokuto testnet contracts and explorer-supported tooling.",
        docs_url: "https://docs.katana.network/katana/get-started/technical-reference-testnet/",
        explorer_url: "https://bokuto.katanascan.com",
        faucet_url: "https://explorer-bokuto.katanarpc.com/",
        verify_url: "https://docs.katana.network/katana/get-started/technical-reference-testnet/"
      ),
      chain(
        "sei",
        name: "Sei",
        chain_id: 1_329,
        tier: "docs_only",
        network_kind: "mainnet",
        summary: "Sei contracts surfaced from ecosystem docs and explorer pages.",
        docs_url: "https://www.docs.sei.io/evm"
      ),
      chain(
        "sei-testnet",
        name: "Sei Testnet",
        chain_id: 1_328,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "Sei Testnet contracts and explorer-supported tooling.",
        docs_url: "https://www.docs.sei.io/evm",
        explorer_url: "https://testnet.seiscan.io",
        faucet_url: "https://docs.sei.io/providers/faucets",
        verify_url: "https://docs.sei.io/evm/evm-verify-contracts"
      ),
      chain(
        "stable",
        name: "Stable",
        chain_id: 988,
        tier: "docs_only",
        network_kind: "mainnet",
        summary: "Stable contracts surfaced from ecosystem docs and explorer pages.",
        docs_url: "https://docs.stable.xyz/en/developers/mainnet/mainnet-information"
      ),
      chain(
        "stable-testnet",
        name: "Stable Testnet",
        chain_id: 2_201,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "Stable Testnet contracts and explorer-supported tooling.",
        docs_url: "https://docs.stable.xyz/en/developers/testnet/testnet-information",
        explorer_url: "https://testnet.stablescan.xyz",
        faucet_url: "https://faucet.stable.xyz",
        verify_url: "https://testnet.stablescan.xyz/verifyContract"
      ),
      chain(
        "plasma",
        name: "Plasma",
        chain_id: 9_745,
        tier: "docs_only",
        network_kind: "mainnet",
        summary: "Plasma contracts surfaced from ecosystem docs and explorer pages.",
        docs_url: "https://docs.plasma.to/docs/guides/network-configuration/mainnet-details"
      ),
      chain(
        "plasma-testnet",
        name: "Plasma Testnet",
        chain_id: 9_746,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "Plasma Testnet contracts and explorer-supported tooling.",
        docs_url: "https://docs.plasma.to/docs/guides/network-configuration/testnet-details",
        explorer_url: "https://testnet.plasmascan.to",
        faucet_url: "https://gas.zip/faucet/plasma",
        verify_url: "https://docs.plasma.to/docs/guides/smart-contracts/verify-a-contract"
      ),
      chain(
        "megaeth",
        name: "MegaETH",
        chain_id: 4_326,
        tier: "docs_only",
        network_kind: "mainnet",
        summary: "MegaETH contracts surfaced from ecosystem docs and explorer pages.",
        docs_url: "https://docs.megaeth.com/frontier"
      ),
      chain(
        "megaeth-testnet",
        name: "MegaETH Testnet",
        chain_id: 6_343,
        tier: "docs_only",
        network_kind: "testnet",
        summary: "MegaETH Testnet contracts and explorer-supported tooling.",
        docs_url: "https://docs.megaeth.com/testnet",
        faucet_url: "https://testnet.megaeth.com"
      ),
      chain(
        "linea",
        name: "Linea",
        chain_id: 59144,
        tier: "docs_only",
        summary: "Docs-only Linea contracts from the ecosystem's native tokens and leading apps.",
        docs_url: "https://docs.linea.build/",
        contracts: [
          contract("linea", name: "USDC", address: "0x176211869ca2b568f2a7d4ee941e073a821ee1ff", kind: "Token"),
          contract("linea", name: "WETH", address: "0xe5d7c2a44ffddf6b295a15c148167daaaf5cf34f", kind: "Token"),
          contract("linea", name: "Aave V3 Pool", address: "0xc47b8c00b0f69a36fa203ffeac0334874574a8ac", kind: "Lending"),
          contract("linea", name: "Etherex Universal Router", address: "0x85974429677c2a701af470b82f3118e74307826e", kind: "DEX"),
          contract("linea", name: "Etherex Swap Router", address: "0x8be024b5c546b5d45cbb23163e1a4dca8fa5052a", kind: "DEX"),
          contract("linea", name: "Etherex Access Hub Proxy", address: "0x683035188e3670fda1def2a7aa5742dea28ed5f3", kind: "DEX"),
          contract("linea", name: "Etherex REX33 Token", address: "0xe4eeb461ad1e4ef8b8ef71a33694ccd84af051c4", kind: "Token")
        ]
      ),
      chain(
        "unichain",
        name: "Unichain",
        chain_id: 130,
        tier: "docs_only",
        summary: "Unichain's core contracts for v2, v3, v4, and native token deployment.",
        docs_url: "https://docs.unichain.org/docs/technical-information/contract-addresses",
        contracts: [
          contract("unichain", name: "USDC", address: "0x078d782b760474a361dda0af3839290b0ef57ad6", kind: "Token"),
          contract("unichain", name: "USDT0", address: "0x9151434b16b9763660705744891fa906f660ecc5", kind: "Token"),
          contract("unichain", name: "WETH", address: "0x4200000000000000000000000000000000000006", kind: "Token"),
          contract("unichain", name: "Uniswap v4 PoolManager", address: "0x1f98400000000000000000000000000000000004", kind: "DEX"),
          contract("unichain", name: "Uniswap v3 Factory", address: "0x1f98400000000000000000000000000000000003", kind: "DEX"),
          contract("unichain", name: "Uniswap v2 Factory", address: "0x1f98400000000000000000000000000000000002", kind: "DEX"),
          contract("unichain", name: "Universal Router", address: "0xef740bf23acae26f6492b10de645d6b98dc8eaf3", kind: "DEX"),
          contract("unichain", name: "SwapRouter02", address: "0x73855d06de49d0fe4a9c42636ba96c62da12ff9c", kind: "DEX")
        ]
      ),
      chain(
        "berachain",
        name: "Berachain",
        chain_id: 80094,
        tier: "docs_only",
        summary: "Berachain BEX and Proof-of-Liquidity contracts plus the native tokens.",
        docs_url: "https://docs.berachain.com/build/bex/deployed-contracts",
        contracts: [
          contract("berachain", name: "BEX Vault", address: "0x4be03f781c497a489e3cb0287833452ca9b9e80b", kind: "DEX"),
          contract("berachain", name: "Protocol Fees Collector", address: "0xb8cf46cf1b1476e707619913a70b2085d26f1707", kind: "DEX"),
          contract("berachain", name: "Balancer Helpers", address: "0x5083737ec75a728c265be578c9d0d5333a2c5951", kind: "DEX"),
          contract("berachain", name: "Pool Creation Helper", address: "0x55dcce8165c88aad4403a15a9ce3a8e244657dd2", kind: "DEX"),
          contract("berachain", name: "Composable Stable Pool Factory", address: "0xdfa30bda0375d4763711ab0cc8d91b20bfcc87e1", kind: "DEX"),
          contract("berachain", name: "BGT", address: "0x656b95e550c07a9ffe548bd4085c72418ceb1dba", kind: "Token"),
          contract("berachain", name: "HONEY", address: "0xfcbD14DC51f0A4d49d5E53C2E0950e0bC26d0Dce", kind: "Token"),
          contract("berachain", name: "WBERA", address: "0x6969696969696969696969696969696969696969", kind: "Token")
        ]
      ),
      chain(
        "blast",
        name: "Blast",
        chain_id: 81457,
        tier: "docs_only",
        summary: "Blast's core bridge and token contracts on the L2.",
        docs_url: "https://docs.blast.io/building/contracts",
        contracts: [
          contract("blast", name: "L2StandardBridge", address: "0x4200000000000000000000000000000000000010", kind: "Bridge"),
          contract("blast", name: "L2BlastBridge", address: "0x4300000000000000000000000000000000000005", kind: "Bridge"),
          contract("blast", name: "L2ERC721Bridge", address: "0x4200000000000000000000000000000000000014", kind: "Bridge"),
          contract("blast", name: "L2CrossDomainMessenger", address: "0x4200000000000000000000000000000000000007", kind: "Bridge"),
          contract("blast", name: "OptimismMintableERC20Factory", address: "0x4200000000000000000000000000000000000012", kind: "Infra"),
          contract("blast", name: "WETH", address: "0x4300000000000000000000000000000000000004", kind: "Token"),
          contract("blast", name: "USDB", address: "0x4300000000000000000000000000000000000003", kind: "Token")
        ]
      ),
      chain(
        "sonic",
        name: "Sonic",
        chain_id: 146,
        tier: "docs_only",
        summary: "Sonic's core gas, bridge, and gateway infrastructure contracts.",
        docs_url: "https://docs.soniclabs.com/sonic/build-on-sonic/contract-addresses",
        contracts: [
          contract("sonic", name: "Wrapped S", address: "0x039e2fb66102314ce7b64ce5ce3e5183bc94ad38", kind: "Token"),
          contract("sonic", name: "WETH", address: "0x50c42deacd8fc9773493ed674b675be577f2634b", kind: "Token"),
          contract("sonic", name: "USDC", address: "0x29219dd400f2bf60e5a23d13be72b486d4038894", kind: "Token"),
          contract("sonic", name: "EURC", address: "0xe715cba7b5ccb33790cebff1436809d36cb17e57", kind: "Token"),
          contract("sonic", name: "USDT", address: "0x6047828dc181963ba44974801ff68e538da5eaf9", kind: "Token"),
          contract("sonic", name: "SFC", address: "0xfc00face00000000000000000000000000000000", kind: "Infra"),
          contract("sonic", name: "Multicall3", address: "0xca11bde05977b3631167028862be2a173976ca11", kind: "Infra"),
          contract("sonic", name: "MessageBus", address: "0xb5b371b75f9850ddd6cccb6c436db54972a925308", kind: "Bridge")
        ]
      ),
      chain(
        "mantle",
        name: "Mantle",
        chain_id: 5000,
        tier: "docs_only",
        summary: "Mantle contracts pulled from ecosystem deployment guides and protocol docs.",
        docs_url: "https://docs.dodoex.io/en/developer/contracts/dodo-v1-v2/contracts-address/mantle",
        contracts: [
          contract("mantle", name: "WMNT", address: "0x78c1b0c915c4faa5fffa6cabf0219da63d7f4cb8", kind: "Token"),
          contract("mantle", name: "DODO V2 Factory", address: "0x46af6b152f2cb02a3cfcc74014c2617bc4f6cd5c", kind: "DEX"),
          contract("mantle", name: "DODO V2 Router", address: "0x2c2954cf16f974033e1e2345fce1ca434dc14497", kind: "DEX"),
          contract("mantle", name: "Uniswap V3 Factory", address: "0xead128bdf9cff441ef401ec8d18a96b4a2d25252", kind: "DEX"),
          contract("mantle", name: "Nonfungible Position Manager", address: "0x9c3bde004b6383f296112536b1e3612e9229d98d", kind: "DEX"),
          contract("mantle", name: "QuoterV2", address: "0x8f51a95226f8bad1b4b3a0f61f6a53d084a7e033", kind: "DEX"),
          contract("mantle", name: "SwapRouter", address: "0xcf43e529e8c3172c2d30af4c27319acd09ce504d", kind: "DEX"),
          contract("mantle", name: "KlpManager", address: "0x3c4de8fb37055500bb3d18eae8dd0dfff527090e", kind: "Lending")
        ]
      ),
      chain(
        "gnosis",
        name: "Gnosis",
        chain_id: 100,
        tier: "docs_only",
        summary: "Gnosis Chain bridge, staking, and token contracts from the ecosystem docs.",
        docs_url: "https://docs.gnosischain.com/about/specs/gbc/",
        contracts: [
          contract("gnosis", name: "GNO", address: "0x9c58bacc331c9aa871afd802db6379a98e80cedb", kind: "Token"),
          contract("gnosis", name: "xDAI Bridge", address: "0x7301cfa0e1756b71869e93d4e4dca5c7d0eb0aa6", kind: "Bridge"),
          contract("gnosis", name: "USDS Deposit Contract", address: "0x5c183c8a49aba6e31049997a56d75600e27ff8c9", kind: "Bridge"),
          contract("gnosis", name: "GBC Deposit Contract", address: "0x0b98057ea310f4d31f2a452b414647007d1645d9", kind: "Staking"),
          contract("gnosis", name: "GNO->mGNO", address: "0x647507a70ff598f386cb96ae5046486389368c66", kind: "Staking"),
          contract("gnosis", name: "sDAI", address: "0xaf204776c7245bf4147c2612bf6e5972ee483701", kind: "Token"),
          contract("gnosis", name: "wxDAI", address: "0xe91d153e0b41518a2ce8dd3d7944fa863463a97d", kind: "Token"),
          contract("gnosis", name: "SavingsXDAI Adapter", address: "0xd499b51fcfc66bd31248ef4b28d656d67e591a94", kind: "Bridge")
        ]
      ),
      chain(
        "celo",
        name: "Celo",
        chain_id: 42220,
        tier: "docs_only",
        summary: "Celo's core governance, bridge, and Uniswap deployment addresses.",
        docs_url: "https://docs.celo.org/contracts/core-contracts",
        contracts: [
          contract("celo", name: "CeloToken", address: "0x471ece3750da237f93b8e339c536989b8978a438", kind: "Token"),
          contract("celo", name: "StableToken", address: "0xef4d55d6de8e8d73232827cd1e9b2f2dbb45bc80", kind: "Token"),
          contract("celo", name: "Accounts", address: "0x7d21685c17607338b313a7174bab6620bad0aab7", kind: "Governance"),
          contract("celo", name: "Attestations", address: "0xdc553892cdeeed9f575aa0fba099e5847fd88d20", kind: "Governance"),
          contract("celo", name: "Election", address: "0x8d6677192144292870907e3fa8a5527fe55a7ff6", kind: "Governance"),
          contract("celo", name: "PoolManager", address: "0x288dc841a52fca2707c6947b3a777c5e56cd87bc", kind: "DEX"),
          contract("celo", name: "UniversalRouter", address: "0xcb695bc5d3aa22cad1e6df07801b061a05a0233a", kind: "DEX"),
          contract("celo", name: "L1 Standard Bridge", address: "0x1ac1181fc4e4f877963680587aeaa2c90d7ebb95", kind: "Bridge")
        ]
      ),
      chain(
        "fraxtal",
        name: "Fraxtal",
        chain_id: 252,
        tier: "docs_only",
        summary: "Fraxtal's native stablecoins, Fraxswap, and name service contracts.",
        docs_url: "https://docs.frax.com/fraxtal/addresses/frax-tokens",
        contracts: [
          contract("fraxtal", name: "FRAX", address: "0x3432b6a60d23ca0dfca7761b7ab56459d9c964d0", kind: "Token"),
          contract("fraxtal", name: "WFRAX", address: "0xfc00000000000000000000000000000000000002", kind: "Token"),
          contract("fraxtal", name: "frxUSD", address: "0xfc00000000000000000000000000000000000001", kind: "Token"),
          contract("fraxtal", name: "sfrxUSD", address: "0xfc00000000000000000000000000000000000008", kind: "Token"),
          contract("fraxtal", name: "frxETH", address: "0xfc00000000000000000000000000000000000006", kind: "Token"),
          contract("fraxtal", name: "Fraxswap Factory", address: "0xe30521fe7f3beb6ad556887b50739d6c7ca667e6", kind: "DEX"),
          contract("fraxtal", name: "Fraxswap Router", address: "0x7ae2a0f3d9ef911a0a3f726fa9fbfca25dc18f7a", kind: "DEX"),
          contract("fraxtal", name: "FNS Registry", address: "0xd8599630ddd05aaa21ce48f9d596aab260352cb7", kind: "Identity")
        ]
      ),
      chain(
        "taiko",
        name: "Taiko",
        chain_id: 167000,
        tier: "docs_only",
        summary: "Taiko Alethia bridge, tokens, and operator contracts surfaced in explorer pages.",
        docs_url: "https://taikoscan.io/address/0x1670000000000000000000000000000000000001",
        contracts: [
          contract("taiko", name: "Taiko Bridge", address: "0x1670000000000000000000000000000000000001", kind: "Bridge"),
          contract("taiko", name: "Taiko Contract Owner", address: "0xf8ff2af0dc1d5ba4811f22acb02936a1529fd2be", kind: "Governance"),
          contract("taiko", name: "TAIKO Token", address: "0xa9d23408b9ba935c230493c40c73824df71a0975", kind: "Token"),
          contract("taiko", name: "WETH Token", address: "0xa51894664a773981c6c112c43ce576f315d5b1b6", kind: "Token"),
          contract("taiko", name: "USDT Token", address: "0x2def195713cf4a606b49d07e520e22c17899a736", kind: "Token"),
          contract("taiko", name: "Gate Internal", address: "0x85faa6c1f2450b9caea300838981c2e6e120c35c", kind: "Bridge"),
          contract("taiko", name: "Taiko Bridge Helper", address: "0x464fc339add314932920d3e060745bd7ea3e92ad", kind: "Bridge")
        ]
      ),
      chain(
        "world",
        name: "World Chain",
        chain_id: 480,
        tier: "docs_only",
        summary: "World Chain contracts for identity, tokens, and account abstraction primitives.",
        docs_url: "https://docs.world.org/world-chain/developers/world-chain-contracts",
        contracts: [
          contract("world", name: "World ID Router", address: "0x17b354dd2595411ff79041f930e491a4df39a278", kind: "Identity"),
          contract("world", name: "World ID Address Book", address: "0x57b930d551e677cc36e2fa036ae2fe8fdae0330d", kind: "Identity"),
          contract("world", name: "WLD", address: "0x2cfc85d8e48f8eab294be644d9e25c3030863003", kind: "Token"),
          contract("world", name: "WETH", address: "0x4200000000000000000000000000000000000006", kind: "Token"),
          contract("world", name: "USDC", address: "0x79a02482a880bce3f13e09da970dc34db4cd24d1", kind: "Token"),
          contract("world", name: "SafeProxyFactory", address: "0xa6b71e26c5e0845f74c812102ca7114b6a896ab2", kind: "Infra"),
          contract("world", name: "EAS", address: "0x4200000000000000000000000000000000000021", kind: "Infra"),
          contract("world", name: "Entrypoint v0.7", address: "0x0000000071727de22e5e9d8baf0edac6f37da032", kind: "Infra")
        ]
      ),
      chain(
        "abstract",
        name: "Abstract",
        chain_id: 2741,
        tier: "docs_only",
        summary: "Abstract system contracts that power account abstraction and deployment.",
        docs_url: "https://docs.abs.xyz/how-abstract-works/system-contracts/list-of-system-contracts",
        contracts: [
          contract("abstract", name: "AccountCodeStorage", address: "0x0000000000000000000000000000000000008002", kind: "System"),
          contract("abstract", name: "NonceHolder", address: "0x0000000000000000000000000000000000008003", kind: "System"),
          contract("abstract", name: "KnownCodesStorage", address: "0x0000000000000000000000000000000000008004", kind: "System"),
          contract("abstract", name: "ContractDeployer", address: "0x0000000000000000000000000000000000008006", kind: "System"),
          contract("abstract", name: "L1Messenger", address: "0x0000000000000000000000000000000000008008", kind: "System"),
          contract("abstract", name: "L2BaseToken", address: "0x000000000000000000000000000000000000800a", kind: "System"),
          contract("abstract", name: "SystemContext", address: "0x000000000000000000000000000000000000800b", kind: "System"),
          contract("abstract", name: "Create2Factory", address: "0x0000000000000000000000000000000000010000", kind: "System")
        ]
      )
    ].index_by(&:slug).freeze
  end
end
