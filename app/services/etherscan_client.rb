class EtherscanClient
  BASE_URL = "https://api.etherscan.io/v2/api"
  TIMEOUT = 10

  class Error < StandardError; end
  class NotVerifiedError < Error; end

  def initialize(chain)
    @chain = chain
    @api_key = Rails.application.credentials.dig(:etherscan, :api_key) || ENV["ETHERSCAN_API_KEY"]
  end

  def fetch_contract_info(address)
    source = fetch_source_code(address)

    if source["Proxy"] == "1" && source["Implementation"].present?
      impl_address = source["Implementation"]
      impl_source = fetch_source_code(impl_address)
      impl_abi = fetch_abi(impl_address)

      {
        name: impl_source["ContractName"],
        compiler_version: impl_source["CompilerVersion"],
        source_code: impl_source["SourceCode"],
        abi: impl_abi,
        natspec: NatSpecExtractor.call(impl_source["SourceCode"]),
        implementation_address: impl_address.downcase,
        verified_at: Time.current
      }
    else
      {
        name: source["ContractName"],
        compiler_version: source["CompilerVersion"],
        source_code: source["SourceCode"],
        abi: fetch_abi(address),
        natspec: NatSpecExtractor.call(source["SourceCode"]),
        implementation_address: nil,
        verified_at: Time.current
      }
    end
  end

  private

  def fetch_source_code(address)
    result = request(module: "contract", action: "getsourcecode", address: address)
    data = result.first

    raise NotVerifiedError, "Contract #{address} is not verified on #{@chain.name}" if data["ABI"] == "Contract source code not verified"

    data
  end

  def fetch_abi(address)
    result = request(module: "contract", action: "getabi", address: address)
    JSON.parse(result)
  end

  def request(params)
    response = connection.get do |req|
      req.params = params.merge(chainid: @chain.chain_id, apikey: @api_key)
    end

    body = JSON.parse(response.body)

    raise Error, "Etherscan API error: #{body["message"]} - #{body["result"]}" unless body["status"] == "1"

    body["result"]
  end

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |f|
      f.request :retry, max: 2, interval: 0.5, backoff_factor: 2
      f.options.timeout = TIMEOUT
      f.options.open_timeout = TIMEOUT
    end
  end
end
