class WarmupGovernanceCacheJob < ApplicationJob
  queue_as :default

  # Periodic: walks every curated slug and enqueues a per-contract refresh.
  # Each per-contract job is a cheap no-op when the freshness cache is still
  # warm, so running every 30 minutes is safe — only the contracts that
  # actually need a re-scan pay the Etherscan cost.
  def perform
    Contract.where.not(catalog_slug: nil).find_each do |contract|
      GovernanceTimelineRefreshJob.perform_later(contract.id)
    end
  end
end
