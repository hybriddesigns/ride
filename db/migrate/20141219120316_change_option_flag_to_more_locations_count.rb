class ChangeOptionFlagToMoreLocationsCount < ActiveRecord::Migration
  def change
	remove_column :cab_requests, :options_flag
	add_column    :cab_requests, :more_location_count, :integer  	
  end
end
