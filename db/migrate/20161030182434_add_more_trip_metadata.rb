class AddMoreTripMetadata < ActiveRecord::Migration
  def change
    add_column :trips, :scheduled_time, :datetime
    add_column :trips, :banned_routes, :string
    add_column :trips, :preferred_routes, :string
  end
end
