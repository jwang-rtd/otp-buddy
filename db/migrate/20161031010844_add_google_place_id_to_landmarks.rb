class AddGooglePlaceIdToLandmarks < ActiveRecord::Migration
  def change
    add_column :landmarks, :google_place_id, :string
  end
end
