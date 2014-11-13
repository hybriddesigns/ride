class CreateCabRequests < ActiveRecord::Migration
  def change
    create_table :cab_requests do |t|

      t.timestamps
    end
  end
end
