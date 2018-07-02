class DropAndAddGooglePlacesIdForOracle < ActiveRecord::Migration
  def change
    remove_column :landmarks, :google_place_id
    remove_column :places, :google_place_id
    add_column :landmarks, :google_place_id, :text
    add_column :places, :google_place_id, :text
  end
end
