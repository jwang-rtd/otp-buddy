class AddForeignKeys < ActiveRecord::Migration
  def change
    add_foreign_key :itineraries, :requests
    add_foreign_key :requests, :trips
    add_foreign_key :trips, :places, column: :origin_id
    add_foreign_key :trips, :places, column: :destination_id
    add_index :itineraries, :request_id
    add_index :requests, :trip_id
    add_index :trips, :origin_id
    add_index :trips, :destination_id
  end
end