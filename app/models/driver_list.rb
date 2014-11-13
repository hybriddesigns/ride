class DriverList < ActiveRecord::Base
	belongs_to :cab_request
	belongs_to :driver
end
