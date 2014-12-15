class AddOrderedToCabRequest < ActiveRecord::Migration
  def change
    add_column :cab_requests, :ordered, :boolean
  end
end
