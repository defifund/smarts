# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_21_150000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "access_token", null: false
    t.string "access_token_secret", null: false
    t.datetime "created_at", null: false
    t.string "handle", null: false
    t.string "locale", null: false
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "provider", "locale"], name: "index_accounts_on_user_id_and_provider_and_locale", unique: true
  end

  create_table "articles", force: :cascade do |t|
    t.string "category", null: false
    t.jsonb "content", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "published_at"
    t.string "slug", null: false
    t.string "subcategory"
    t.jsonb "summary", default: {}, null: false
    t.jsonb "title", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["category", "subcategory"], name: "index_articles_on_category_and_subcategory"
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
    t.index ["user_id"], name: "index_articles_on_user_id"
  end

  create_table "chains", force: :cascade do |t|
    t.integer "chain_id", null: false
    t.datetime "created_at", null: false
    t.string "explorer_api_url", null: false
    t.string "name", null: false
    t.string "rpc_url"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["chain_id"], name: "index_chains_on_chain_id", unique: true
    t.index ["slug"], name: "index_chains_on_slug", unique: true
  end

  create_table "contracts", force: :cascade do |t|
    t.jsonb "abi"
    t.string "address", null: false
    t.jsonb "ai_natspec"
    t.bigint "chain_id", null: false
    t.string "compiler_version"
    t.string "contract_type"
    t.datetime "created_at", null: false
    t.bigint "governance_last_scanned_block"
    t.string "implementation_address"
    t.string "name"
    t.jsonb "natspec"
    t.text "source_code"
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["chain_id", "address"], name: "index_contracts_on_chain_id_and_address", unique: true
    t.index ["chain_id"], name: "index_contracts_on_chain_id"
  end

  create_table "governance_events", force: :cascade do |t|
    t.jsonb "args", default: {}, null: false
    t.bigint "block_number", null: false
    t.datetime "block_timestamp"
    t.string "category", null: false
    t.bigint "contract_id", null: false
    t.datetime "created_at", null: false
    t.string "event_name", null: false
    t.integer "log_index", null: false
    t.string "summary"
    t.string "tx_hash", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_id", "block_number"], name: "index_governance_events_on_contract_and_block", order: { block_number: :desc }
    t.index ["contract_id", "category"], name: "index_governance_events_on_contract_and_category"
    t.index ["contract_id", "tx_hash", "log_index"], name: "index_governance_events_unique", unique: true
    t.index ["contract_id"], name: "index_governance_events_on_contract_id"
  end

  create_table "protocol_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "display_name", null: false
    t.string "match_type", null: false
    t.integer "priority", default: 100, null: false
    t.string "protocol_key", null: false
    t.jsonb "required_selectors", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["match_type", "priority"], name: "index_protocol_templates_on_match_type_and_priority"
    t.index ["protocol_key"], name: "index_protocol_templates_on_protocol_key", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "api_token_digest", null: false
    t.string "api_token_prefix", null: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["api_token_prefix"], name: "index_users_on_api_token_prefix"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "x_queue_tweets", force: :cascade do |t|
    t.bigint "account_id"
    t.string "account_type"
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "posted_at"
    t.datetime "scheduled_at"
    t.bigint "source_id"
    t.string "source_type"
    t.integer "status", default: 0, null: false
    t.string "thread_id"
    t.integer "thread_position"
    t.datetime "updated_at", null: false
    t.string "x_tweet_id"
    t.index ["account_type", "account_id"], name: "index_x_queue_tweets_on_account"
    t.index ["scheduled_at"], name: "index_x_queue_tweets_on_scheduled_at"
    t.index ["source_type", "source_id"], name: "index_x_queue_tweets_on_source"
    t.index ["status"], name: "index_x_queue_tweets_on_status"
    t.index ["thread_id"], name: "index_x_queue_tweets_on_thread_id"
    t.index ["x_tweet_id"], name: "index_x_queue_tweets_on_x_tweet_id", unique: true, where: "(x_tweet_id IS NOT NULL)"
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "articles", "users"
  add_foreign_key "contracts", "chains"
  add_foreign_key "governance_events", "contracts"
  add_foreign_key "sessions", "users"
end
