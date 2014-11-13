class AddTimeLimitToCabRequests < ActiveRecord::Migration
  def change
    add_column :cab_requests, :time_limit, :datetime
  end
end
