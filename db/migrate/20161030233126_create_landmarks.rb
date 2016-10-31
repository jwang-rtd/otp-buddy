class CreateLandmarks < ActiveRecord::Migration
  def change
    create_table :landmarks do |t|
      t.string :name
      t.string :address
      t.string :city
      t.string :state
      t.string :zip
      t.string :lat
      t.string :lng
      t.boolean :old
      t.string :landmark_type
      t.timestamps null: false
    end
  end
end
