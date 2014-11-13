class CabRequest < ActiveRecord::Base
	belongs_to :driver
	has_many :driver_lists
end
