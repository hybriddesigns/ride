class AddMoreLocationsToCabRequest < ActiveRecord::Migration
  def change
    add_column :cab_requests, :more_locations, :text
  end
end
