class AddMoreLocationCountToDriverRegistrationRequest < ActiveRecord::Migration
  def change
    add_column :driver_registration_requests, :more_location_count, :integer
  end
end
