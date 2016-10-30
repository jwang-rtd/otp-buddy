class AddOriginDestinationToTrips < ActiveRecord::Migration
  def change
    add_column :trips, :origin_id, :integer
    add_column :trips, :destination_id, :integer
  end
end
