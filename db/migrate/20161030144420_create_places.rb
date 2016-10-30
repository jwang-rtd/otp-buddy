class CreatePlaces < ActiveRecord::Migration
  def change
    create_table :places do |t|
      t.string :lat, null: false
      t.string :lng, null: false
      t.timestamps null: false
    end
  end
end
