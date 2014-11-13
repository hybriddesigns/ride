class CreateDriverLists < ActiveRecord::Migration
  def change
    create_table :driver_lists do |t|
      t.integer :driver_id
      t.string :user_cell_no
      t.datetime :deletion_time

      t.timestamps
    end
  end
end
