class AddDriverIdToCabRequests < ActiveRecord::Migration
  def change
    add_column :cab_requests, :driver_id, :integer
  end
end
