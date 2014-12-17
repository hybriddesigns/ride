class AddFinalDriverIdToCabRequest < ActiveRecord::Migration
  def change
    add_column :cab_requests, :final_driver_id, :integer
  end
end
