class CabRequest < ActiveRecord::Base
	belongs_to :driver
	has_many :driver_lists

       # @cab_requests=CabRequest.where(:user_cell_no=>params[:user_cell_no])
   public
    def self.getCabRequests(user_cell_no)
    	@cab_requests=CabRequest.where(:user_cell_no=>user_cell_no)
    	return @cab_requests
    end

    def register_request(user_cell_no, lat, long, location)
    	self.user_cell_no=user_cell_no
    	self.latitude=lat
    	self.longitude=long
    	self.location=location
    	self.status=false
    	self.broadcast=false
    	self.count=0.to_i
    	self.save
    end

    def lock_choice(lat, long, location)
    	self.update_attribute(:latitude, lat)
        self.update_attribute(:longitude, long)
        self.update_attribute(:location, location)
    end

    def increment_count
    	@count=self.count+1
    	self.update_attribute(:count, @count)
    end

    def self.is_new(cell_no)
      @user=CabRequest.where(:user_cell_no=> cell_no)
      @old_request=@user.where(:status => false).last
      if @old_request.present?
        return false
      else
        return true
      end
    end
end