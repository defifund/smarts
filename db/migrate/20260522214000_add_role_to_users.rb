# frozen_string_literal: true

class AddRoleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :string, null: false, default: "user"
  end
end
