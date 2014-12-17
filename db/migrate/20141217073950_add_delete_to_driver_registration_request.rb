class AddDeleteToDriverRegistrationRequest < ActiveRecord::Migration
  def change
    add_column :driver_registration_requests, :deleted, :boolean
  end
end
