class AddUserCellNoToCabRequests < ActiveRecord::Migration
  def change
    add_column :cab_requests, :user_cell_no, :string
  end
end
