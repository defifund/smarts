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
    Chain.where(slug: "bnb").delete_all
  end
end
