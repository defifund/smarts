require "yaml"

require "test_helper"

class Chains::SeederTest < ActiveSupport::TestCase
  test "registers every chain from db/seeds/chains.rb" do
    seeded_count = Chains::Seeder.call

    data = YAML.safe_load_file(Rails.root.join("db/seeds/chains.rb"), symbolize_names: true)
    assert_equal data.length, seeded_count
    data.each do |attrs|
      chain = Chain.find_by!(slug: attrs[:slug])
      assert_equal attrs[:name],     chain.name
      assert_equal attrs[:chain_id], chain.chain_id
      assert_equal attrs[:tier],     chain.tier
    end
  end

  test "is idempotent: calling twice produces no duplicates" do
    before = Chain.count
    2.times { Chains::Seeder.call }
    after = Chain.count

    assert_equal before, after if before == Chain.count
    assert_equal Chain.where(slug: "eth").count, 1
  end

  test "updates existing chain metadata when seed file changes" do
    chain = chains(:ethereum)
    chain.update!(name: "Mistyped Ethereum")
    assert_equal "Mistyped Ethereum", chain.reload.name

    Chains::Seeder.call

    assert_equal "Ethereum", chain.reload.name
  end
end
