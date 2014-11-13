class CreateDrivers < ActiveRecord::Migration
  def change
    create_table :drivers do |t|
      t.string :name
      t.float :location_lat
      t.float :location_long
      t.string :location

      t.timestamps
    end
  end
end
