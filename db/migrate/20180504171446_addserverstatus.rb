class Addserverstatus < ActiveRecord::Migration
  def change
    add_column :itineraries, :server_status, :integer
  end
end
