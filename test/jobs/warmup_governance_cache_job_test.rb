require "test_helper"

class WarmupGovernanceCacheJobTest < ActiveJob::TestCase
  test "enqueues one refresh job per indexed curated contract" do
    eth = chains(:ethereum)
    Contract.create!(
      chain: eth,
      address: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
      name: "USDC",
      catalog_slug: "usdc-eth"
    )

    assert_enqueued_with(job: GovernanceTimelineRefreshJob) do
      WarmupGovernanceCacheJob.perform_now
    end
  end

  test "skips slugs whose chain is not configured" do
    # No contracts present matching any curated slug → no jobs enqueued.
    assert_no_enqueued_jobs only: GovernanceTimelineRefreshJob do
      WarmupGovernanceCacheJob.perform_now
    end
  end

  test "enqueues governance refreshes for every indexed Polymarket curated contract" do
    Chains::Seeder.call

    assert_enqueued_jobs Contract.where.not(catalog_slug: nil).count, only: GovernanceTimelineRefreshJob do
      WarmupGovernanceCacheJob.perform_now
    end
  end
end
