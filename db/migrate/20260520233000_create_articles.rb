class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :slug, null: false
      t.string :category, null: false
      t.string :subcategory
      t.jsonb :title, null: false, default: {}
      t.jsonb :summary, null: false, default: {}
      t.jsonb :content, null: false, default: {}
      t.datetime :published_at

      t.timestamps
    end

    add_index :articles, :slug, unique: true
    add_index :articles, [ :category, :subcategory ]
    add_index :articles, :published_at
  end
end
