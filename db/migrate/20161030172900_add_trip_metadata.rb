class AddTripMetadata < ActiveRecord::Migration
  def change
    add_column :trips, :token, :string
    add_column :trips, :optimize, :string, default: "TIME"
    add_column :trips, :max_walk_miles, :float
    add_column :trips, :max_walk_seconds, :integer
    add_column :trips, :walk_mph, :float
    add_column :trips, :max_bike_miles, :float
    add_column :trips, :num_itineraries, :integer, default: 3
    add_column :trips, :min_transfer_seconds, :integer
    add_column :trips, :max_transfer_seconds, :integer
    add_column :trips, :source_tag, :string
  end
end
