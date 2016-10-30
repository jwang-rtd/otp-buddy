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

ActiveRecord::Schema.define(version: 20161030182434) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "places", force: :cascade do |t|
    t.string   "lat",        null: false
    t.string   "lng",        null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "settings", force: :cascade do |t|
    t.string   "key",        null: false
    t.text     "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trips", force: :cascade do |t|
    t.boolean  "arrive_by",            default: true,   null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "origin_id"
    t.integer  "destination_id"
    t.string   "token"
    t.string   "optimize",             default: "TIME"
    t.float    "max_walk_miles"
    t.integer  "max_walk_seconds"
    t.float    "walk_mph"
    t.float    "max_bike_miles"
    t.integer  "num_itineraries",      default: 3
    t.integer  "min_transfer_seconds"
    t.integer  "max_transfer_seconds"
    t.string   "source_tag"
    t.datetime "scheduled_time"
    t.string   "banned_routes"
    t.string   "preferred_routes"
  end

end
