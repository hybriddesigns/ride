class CreateDriverRegistrationRequests < ActiveRecord::Migration
  def change
    create_table :driver_registration_requests do |t|
      t.string :cell_no
      t.text :location
      t.boolean :active

      t.timestamps
    end
  end
end
