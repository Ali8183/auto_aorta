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

ActiveRecord::Schema[8.1].define(version: 2026_10_23_233000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "listings", force: :cascade do |t|
    t.string "title"
    t.string "brand"
    t.string "model_name"
    t.integer "year"
    t.decimal "price", precision: 12, scale: 2
    t.integer "mileage"
    t.string "fuel_type"
    t.string "transmission"
    t.text "description"
    t.integer "status", default: 0, null: false
    t.integer "hero_photo_id"
    t.datetime "optimized_at"
    t.datetime "auto_published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color", default: "Metalik Gri"
    t.string "body_type", default: "Sedan"
    t.string "tramer", default: "Hasar Kaydı Yok / 0 TL"
    t.string "expertise", default: "Hatasız / Boyasız / Değişensiz"
    t.string "dealer_phone", default: "+90 532 500 40 30"
    t.string "dealer_name", default: "AutoAorta Premier Fleet"
  end

  create_table "photo_analyses", force: :cascade do |t|
    t.integer "listing_id", null: false
    t.integer "blob_id", null: false
    t.string "detected_angle"
    t.integer "quality_score"
    t.boolean "is_hero_candidate", default: false, null: false
    t.integer "spin_order", default: 0, null: false
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blob_id"], name: "index_photo_analyses_on_blob_id"
    t.index ["listing_id", "spin_order"], name: "index_photo_analyses_on_listing_id_and_spin_order"
    t.index ["listing_id"], name: "index_photo_analyses_on_listing_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "photo_analyses", "listings"
end
