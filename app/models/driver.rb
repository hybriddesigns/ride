class Driver < ActiveRecord::Base
	has_many :cab_requests
	has_many :driver_lists
    acts_as_mappable :default_units => :kms,
                   :default_formula => :sphere,
                   :lat_column_name => :location_lat,
                   :lng_column_name => :location_long
 	
    def self.is_not_driver(cell_no)
      @driver=Driver.where(:cell_no=>cell_no).last
      if @driver.present?
        return false
      else
        return true
      end
    end

    def confirm_deal
      @cab_request = CabRequest.where(:current_driver_id => self.id).where(:status => false).last
      @cab_request.update_attributes(:status => true)
    end
end
