class AddCountToCabRequests < ActiveRecord::Migration
  def change
    add_column :cab_requests, :count, :integer
  end
end
