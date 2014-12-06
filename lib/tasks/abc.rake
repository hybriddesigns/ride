namespace :events do
  desc "Rake task to test whenever"
  task :fetch => :environment do
    
@passed_time=Time.now-6.minutes
@cab_requests=CabRequest.where(:status=>false, :broadcast=>false).where("updated_at < ?", @passed_time)

@cab_requests.each do |cab_request|
	#send broadcast to all remaining drivers
  if cab_request.driver_ids.present?
	cab_request.update_attribute(:broadcast, true)
  end
end

puts "task 1 done"

@passed_time=Time.now-1.minutes
@cab_requests=CabRequest.where(:status=>false, :broadcast=>false).where("updated_at < ?", @passed_time)

@cab_requests.each do |cab_request|
  if cab_request.driver_ids.present?  
  	@driver_ids=cab_request.driver_ids
  	@driver_ids=@driver_ids.split(%r{,\i*})
      cab_request.update_attribute(:driver_id, @driver_ids.shift)
      @driver_ids.each do |x|
      	@driver=Driver.find(x.to_i)
      	puts "1-"+@driver.cell_no
      end
      @driver_ids=@driver_ids.join(",")
      cab_request.update_attribute(:driver_ids, @driver_ids)
  end
end

puts "task 2 done"

@passed_time=Time.now-10.minutes
@cab_requests=CabRequest.where(:status=>false, :broadcast=>false).where("updated_at < ?", @passed_time)

@cab_requests.each do |cab_request|
	cab_request.delete
end
puts "task 3 done"
end
end

