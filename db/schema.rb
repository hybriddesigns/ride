# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20141219120316) do

  create_table "cab_requests", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "location"
    t.float    "latitude",            limit: 24
    t.float    "longitude",           limit: 24
    t.integer  "current_driver_id"
    t.string   "customer_cell_no"
    t.boolean  "broadcast"
    t.boolean  "status"
    t.string   "chosen_drivers_ids"
    t.text     "more_locations"
    t.boolean  "ordered"
    t.boolean  "location_selected"
    t.integer  "offer_count"
    t.boolean  "broadcasted"
    t.boolean  "deleted"
    t.integer  "final_driver_id"
    t.boolean  "closed"
    t.integer  "more_location_count"
  end

  create_table "driver_registration_requests", force: true do |t|
    t.string   "cell_no"
    t.text     "location"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "more_location_count"
    t.string   "searched_location"
    t.boolean  "deleted"
  end

  create_table "drivers", force: true do |t|
    t.string   "name"
    t.float    "location_lat",  limit: 24
    t.float    "location_long", limit: 24
    t.string   "location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cell_no"
  end

  create_table "locations", force: true do |t|
    t.string   "location_name"
    t.float    "latitude",      limit: 24
    t.float    "longitude",     limit: 24
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "send_sms", id: false, force: true do |t|
    t.string  "momt",     limit: 50, null: false
    t.string  "sender",   limit: 50, null: false
    t.string  "receiver", limit: 50, null: false
    t.text    "msgdata",             null: false
    t.integer "sms_type",            null: false
    t.string  "smsc_id",  limit: 50, null: false
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "role"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
