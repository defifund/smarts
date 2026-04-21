class AddImplementationAddressToContracts < ActiveRecord::Migration[8.1]
  def change
    add_column :contracts, :implementation_address, :string
  end
end
