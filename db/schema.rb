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

ActiveRecord::Schema[8.1].define(version: 2026_02_26_155649) do
  create_table "package_versions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "dependencies", default: {}
    t.text "description"
    t.string "dragonruby_version", default: ">= 3.0"
    t.integer "package_id", null: false
    t.json "scripts", default: []
    t.text "source_code"
    t.json "tags", default: []
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.index ["package_id", "version"], name: "index_package_versions_on_package_id_and_version", unique: true
    t.index ["package_id"], name: "index_package_versions_on_package_id"
  end

  create_table "packages", force: :cascade do |t|
    t.string "author", null: false
    t.datetime "created_at", null: false
    t.json "dependencies", default: {}
    t.string "description"
    t.string "dragonruby_version", default: ">= 3.0"
    t.string "latest_version", default: "1.0.0"
    t.string "name", null: false
    t.text "samples"
    t.json "scripts", default: []
    t.json "tags", default: []
    t.datetime "updated_at", null: false
    t.index ["author"], name: "index_packages_on_author"
    t.index ["name"], name: "index_packages_on_name", unique: true
    t.index ["tags"], name: "index_packages_on_tags"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "package_versions", "packages"
end
