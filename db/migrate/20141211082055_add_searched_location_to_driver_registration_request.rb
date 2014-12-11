class AddSearchedLocationToDriverRegistrationRequest < ActiveRecord::Migration
  def change
    add_column :driver_registration_requests, :searched_location, :string
  end
end
