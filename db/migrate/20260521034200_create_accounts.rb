class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :provider, null: false
      t.string :handle, null: false
      t.string :locale, null: false
      t.string :access_token, null: false
      t.string :access_token_secret, null: false

      t.timestamps
    end

    add_index :accounts, [ :user_id, :provider, :locale ], unique: true
  end
end
