class EnrichContractAiJob < ApplicationJob
  queue_as :default

  # Generates AI-drafted NatSpec for a contract and broadcasts a Turbo morph
  # refresh so the open show page picks up the new docs without a reload.
  def perform(contract)
    enriched = ContractDocument::AiEnricher.call(contract)
    return if enriched["functions"].blank?

    contract.update!(ai_natspec: enriched)
    Turbo::StreamsChannel.broadcast_refresh_to(contract)
  end
end
