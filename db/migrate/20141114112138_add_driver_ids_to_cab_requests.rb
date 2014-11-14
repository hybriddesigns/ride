class AddDriverIdsToCabRequests < ActiveRecord::Migration
  def change
    add_column :cab_requests, :driver_ids, :string
  end
end
