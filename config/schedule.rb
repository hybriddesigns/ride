# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#


set :environment, "development"
set :output, {:error => "log/cron_error_log.log", :standard => "log/cron_log.log"}

every 1.minute  do
  rake "events:fetch"
end


# Learn more: http://github.com/javan/whenever

@passed_time=Time.now-6.minutes
@cab_requests=CabRequest.where(:status=>false, :broadcast=>false).where("updated_time < ?", @passed_time)

@cab_requests.each do |cab_request|
	#send broadcast to all remaining drivers
	cab_request.update_attribute(:broadcast=> true)
end

@passed_time=Time.now-1.minutes
@cab_requests=CabRequest.where(:status=>false, :boradcast=>false).where("updated_time < ?", @passed_time)

@cab_requests.each do |cab_request|
	@driver_ids=cab_request.driver_ids
	@driver_ids=@driver_ids.split(%r{,\i*})
    cab_request.update_attribute(:driver_id=>@driver_ids.shift)
    @driver_ids=@driver_ids.join(",")
    cab_request.update_attribute(:driver_ids=>@driver_ids)
end


@passed_time=Time.now-20.minutes
@cab_requests=CabRequest.where(:status=>false, :boradcast=>false).where("updated_time < ?", @passed_time)

@cab_requests.each do |cab_request|
	cab_request.delete
end