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

ActiveRecord::Schema.define(version: 20141114112138) do

  create_table "cab_requests", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "location"
    t.float    "latitude"
    t.float    "longitude"
    t.integer  "driver_id"
    t.string   "user_cell_no"
    t.boolean  "broadcast"
    t.boolean  "status"
    t.datetime "time_limit"
    t.integer  "count"
    t.string   "driver_ids"
  end

  create_table "driver_lists", force: true do |t|
    t.integer  "driver_id"
    t.string   "user_cell_no"
    t.datetime "deletion_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "drivers", force: true do |t|
    t.string   "name"
    t.float    "location_lat"
    t.float    "location_long"
    t.string   "location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cell_no"
  end

end
