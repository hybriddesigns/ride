class AddBroadcastedToCabRequest < ActiveRecord::Migration
  def change
    add_column :cab_requests, :broadcasted, :boolean
  end
end
