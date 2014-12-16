class AddLocationSelectedToCabRequest < ActiveRecord::Migration
  def change
    add_column :cab_requests, :location_selected, :boolean
    remove_column :cab_requests, :time_limit
  end
end
