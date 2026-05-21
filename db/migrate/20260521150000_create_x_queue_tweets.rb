class CreateXQueueTweets < ActiveRecord::Migration[8.1]
  def change
    create_table :x_queue_tweets do |t|
      t.text :content, null: false
      t.integer :status, null: false, default: 0
      t.datetime :scheduled_at
      t.datetime :posted_at
      t.string :x_tweet_id
      t.string :thread_id
      t.integer :thread_position
      t.references :source, polymorphic: true, index: true
      t.references :account, polymorphic: true, index: true
      t.timestamps
    end

    add_index :x_queue_tweets, :status
    add_index :x_queue_tweets, :thread_id
    add_index :x_queue_tweets, :scheduled_at
    add_index :x_queue_tweets, :x_tweet_id, unique: true, where: "x_tweet_id IS NOT NULL"
  end
end
