class RequestsBelongToTrips < ActiveRecord::Migration
  def change
    add_column :requests, :trip_id, :integer
    add_column :requests, :trip_type, :string
  end
end
