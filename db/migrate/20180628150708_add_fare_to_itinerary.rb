class AddFareToItinerary < ActiveRecord::Migration
  def change
    add_column :itineraries, :fare, :text
  end
end
