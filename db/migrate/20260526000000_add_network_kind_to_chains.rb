class AddNetworkKindToChains < ActiveRecord::Migration[8.1]
  def change
    add_column :chains, :network_kind, :string, null: false, default: "mainnet"
    add_index :chains, :network_kind
  end
end
