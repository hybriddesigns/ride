class AddClosedToCabRequest < ActiveRecord::Migration
  def change
    add_column :cab_requests, :closed, :boolean
  end
end
