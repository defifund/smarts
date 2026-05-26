class AddPresentationFieldsToChains < ActiveRecord::Migration[8.1]
  def change
    add_column :chains, :summary, :text, null: false, default: ""
    add_column :chains, :docs_url, :string
    add_column :chains, :explorer_url, :string
    add_column :chains, :faucet_url, :string
    add_column :chains, :verify_url, :string
    add_column :chains, :display_order, :integer

    add_index :chains, :display_order
  end
end
