class AddDetailsToPlace < ActiveRecord::Migration
  def change
    add_column :places, :street_address, :string
    add_column :places, :route, :string
    add_column :places, :street_number, :string
    add_column :places, :address, :string
    add_column :places, :state, :string
    add_column :places, :city, :string
    add_column :places, :zip, :string
    add_column :places, :raw_address, :string
    add_column :places, :name, :string
    add_column :places, :google_place_id, :string
    add_column :places, :stop_code, :string
    add_column :places, :types, :text
    add_column :places, :address_components_raw, :text
  end
end
