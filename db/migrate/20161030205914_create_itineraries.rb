class CreateItineraries < ActiveRecord::Migration
  def change
    create_table :itineraries do |t|
      t.integer :request_id
      t.integer :duration
      t.integer :walk_time
      t.integer :transit_time
      t.integer :wait_time
      t.float :walk_distance
      t.integer :transfers
      t.text :json_legs
      t.timestamps null: false
    end
  end
end
