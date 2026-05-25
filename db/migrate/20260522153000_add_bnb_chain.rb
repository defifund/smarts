# DEPRECATED PATTERN — kept only because this migration was already shipped
# to master. Do NOT add new per-chain data migrations. Register new chains in
# db/seeds/chains.rb and run Chains::Seeder.call (db:seed runs it).
class AddBnbChain < ActiveRecord::Migration[8.1]
  def up
    Chain.reset_column_information

    Chain.upsert(
      {
        name: "BNB Smart Chain",
        slug: "bnb",
        chain_id: 56,
        explorer_api_url: "https://api.etherscan.io/v2/api",
        rpc_url: "https://bsc-rpc.publicnode.com",
        created_at: Time.current,
        updated_at: Time.current
      },
      unique_by: :index_chains_on_slug
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "BNB chain data migration is not safely reversible"
  end
end
