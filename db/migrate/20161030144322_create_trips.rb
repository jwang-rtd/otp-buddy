class CreateTrips < ActiveRecord::Migration
  def change
    create_table :trips do |t|
      t.boolean :arrive_by, null: false, default: true
      t.timestamps null: false
    end
  end
end
