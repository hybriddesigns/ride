class AddStatusToCabRequests < ActiveRecord::Migration
  def change
    add_column :cab_requests, :status, :boolean
  end
end
