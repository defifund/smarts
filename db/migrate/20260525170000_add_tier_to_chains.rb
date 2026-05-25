class AddTierToChains < ActiveRecord::Migration[8.1]
  def change
    add_column :chains, :tier, :string, default: "full", null: false
    add_index :chains, :tier
  end
end
