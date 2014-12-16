class AddOfferCountToCabRequest < ActiveRecord::Migration
  def change
    add_column :cab_requests, :offer_count, :integer
  end
end
