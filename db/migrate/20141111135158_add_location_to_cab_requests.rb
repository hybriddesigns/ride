class AddLocationToCabRequests < ActiveRecord::Migration
  def change
    add_column :cab_requests, :location, :string
  end
end
