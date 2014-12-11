class ChangeColumnNamesOfCabRequest < ActiveRecord::Migration
  def change
	rename_column :cab_requests, :driver_id,  :current_driver_id
	rename_column :cab_requests, :driver_ids, :chosen_drivers_ids
	remove_column :cab_requests, :count
	add_column    :cab_requests, :options_flag, :boolean
	rename_column :cab_requests, :user_cell_no, :customer_cell_no
  end
end
