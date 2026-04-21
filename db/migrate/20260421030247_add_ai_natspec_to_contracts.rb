class AddAiNatspecToContracts < ActiveRecord::Migration[8.1]
  def change
    add_column :contracts, :ai_natspec, :jsonb
  end
end
