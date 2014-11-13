class AddLongitudeToCabRequests < ActiveRecord::Migration
  def change
    add_column :cab_requests, :longitude, :float
  end
end
