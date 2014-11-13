class Driver < ActiveRecord::Base
	has_many :cab_requests
	has_many :driver_lists
  acts_as_mappable :default_units => :kms,
                   :default_formula => :sphere,
                   :lat_column_name => :location_lat,
                   :lng_column_name => :location_long
end
