class AddCatalogFieldsToContracts < ActiveRecord::Migration[8.1]
  def change
    add_column :contracts, :catalog_name, :string
    add_column :contracts, :catalog_slug, :string
    add_column :contracts, :catalog_kind, :string
    add_column :contracts, :catalog_notes, :text
    add_column :contracts, :catalog_order, :integer

    add_index :contracts, [ :chain_id, :catalog_slug ], unique: true, where: "catalog_slug IS NOT NULL"
    add_index :contracts, [ :chain_id, :catalog_order ]
  end
end
