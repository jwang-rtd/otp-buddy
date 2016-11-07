class AddStartTimeEndTimeToItinerary < ActiveRecord::Migration
  def change
    add_column :itineraries, :start_time, :datetime
    add_column :itineraries, :end_time, :datetime
  end
end
