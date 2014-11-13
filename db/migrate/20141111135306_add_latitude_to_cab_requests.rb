class AddLatitudeToCabRequests < ActiveRecord::Migration
  def change
    add_column :cab_requests, :latitude, :float
  end
end
