class AddStreetNumberAndRouteToLandmarks < ActiveRecord::Migration
  def change
    add_column :landmarks, :street_number, :string
    add_column :landmarks, :route, :string
    add_column :landmarks, :stop_code, :string
    add_column :landmarks, :types, :text
  end
end
