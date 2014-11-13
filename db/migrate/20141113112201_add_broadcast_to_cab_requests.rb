class AddBroadcastToCabRequests < ActiveRecord::Migration
  def change
    add_column :cab_requests, :broadcast, :boolean
  end
end
