class AddDeleteToCabRequest < ActiveRecord::Migration
  def change
    add_column :cab_requests, :deleted, :boolean
  end
end
