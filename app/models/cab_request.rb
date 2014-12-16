class CabRequest < ActiveRecord::Base
	belongs_to :driver
	has_many :driver_lists

  public
    def self.getCabRequests(customer_cell_no)
    	CabRequest.where(:customer_cell_no => customer_cell_no)    	 
    end

    def register_request(customer_cell_no, lat, long, location)
    	self.customer_cell_no = customer_cell_no
    	self.latitude     = lat
    	self.longitude    = long
    	self.location     = location
    	self.status       = false
    	self.broadcast    = false
      self.options_flag = false
      self.ordered      = false
      self.location_selected = false
    	self.save
    end

    def lock_choice(lat, long, location)
    	self.update_attributes(:latitude => lat, :longitude => long, :location => location, :location_selected => true, :ordered => true)
    end

    def update_option_flag
    	self.update_attributes(:options_flag => true)
    end

    def self.is_new(customer_cell_no)
      @cab_request = CabRequest.where(:customer_cell_no => customer_cell_no)
      @old_request = @cab_request.where(:status => false).last
      if @old_request.present?
        return false
      else
        return true
      end
    end

end