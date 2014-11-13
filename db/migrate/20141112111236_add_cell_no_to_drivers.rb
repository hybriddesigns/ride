class AddCellNoToDrivers < ActiveRecord::Migration
  def change
    add_column :drivers, :cell_no, :string
  end
end
