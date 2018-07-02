class ChangeGooglePlaceIdToTextField < ActiveRecord::Migration
  def change
    change_column :landmarks, :google_place_id, :text
    change_column :places, :google_place_id, :text
  end
end
