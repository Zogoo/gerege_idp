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

ActiveRecord::Schema[8.0].define(version: 2025_01_28_233153) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "saml_sp_configs", force: :cascade do |t|
    t.string "name"
    t.string "display_name"
    t.string "entity_id"
    t.string "signing_certificate"
    t.string "encryption_certificate"
    t.boolean "sign_assertions"
    t.boolean "sign_authn_request"
    t.string "certificate"
    t.string "private_key"
    t.string "pv_key_password"
    t.string "relay_state"
    t.string "name_id_attribute"
    t.text "raw_metadata"
    t.text "name_id_formats", default: [], array: true
    t.jsonb "assertion_consumer_services", default: []
    t.jsonb "single_logout_services", default: {}
    t.jsonb "contact_person", default: {}
    t.jsonb "saml_attributes", default: {}
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entity_id"], name: "index_saml_sp_configs_on_entity_id", unique: true
    t.index ["name"], name: "index_saml_sp_configs_on_name", unique: true
  end
end
