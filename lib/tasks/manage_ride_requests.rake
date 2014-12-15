namespace :events do

  desc "Rake task to manage ride requests"
  task :fetch => :environment do
 
    @short_code   = "+2518202"
    @passed_time  = Time.now - 5.minutes

    puts "Check cab requests of 5 minutes old and not responded. Broadcasting to near drivers" 
    puts (Time.now).to_s + @passed_time.to_s

    @cab_requests = CabRequest.where(:status=>false, :broadcast=>false).where("created_at < ?", @passed_time)
    @cab_requests.each do |cab_request|
    	#send broadcast to all remaining drivers
      @drivers_ids  = cab_request.chosen_drivers_ids
      if @drivers_ids.present?
      	cab_request.update_attribute(:broadcast, true)
        @drivers_ids = @drivers_ids.split(",")
        @drivers_ids.each do |driver_id|
          @driver  = Driver.find(driver_id)
          @message = 'Surprise! We found you a new taxi customer. Would you like to take the request? SMS "Y" for Yes, "N" for No' 
          send_message(@driver.cell_no, @message, @short_code)#send message to @driver.cell_no
        end
      else
        cab_request.delete
      end
    end

    @passed_time  = Time.now - 1.minutes
    puts "Check cab requests of 1 minutes and not responded by the chosen driver" 
    puts (Time.now).to_s + @passed_time.to_s

    @cab_requests = CabRequest.where(:status=>false, :broadcast=>false).where("updated_at < ?", @passed_time)
    @cab_requests.each do |cab_request|
      if cab_request.chosen_drivers_ids.present?  
      	@driver_ids = cab_request.chosen_drivers_ids
      	@driver_ids = @driver_ids.split(%r{,\i*})
        @current_driver_id = @driver_ids.first
        cab_request.update_attribute(:current_driver_id, @current_driver_id)
        @current_driver = Driver.find(@current_driver_id)
        @message = 'Surprise! We found you a new taxi customer. Would you like to take the request? SMS "Y" for Yes, "N" for No'
        send_message(@current_driver.cell_no, @message, @short_code)
        @driver_ids.delete_at(0)
        @driver_ids = @driver_ids.join(",")
        cab_request.update_attribute(:chosen_drivers_ids, @driver_ids)
      else
        @message = "Sorry, Taxi is not available in this area for now. Please try later."
        send_message(cab_request.customer_cell_no, @message, @short_code)
        cab_request.delete
      end
    end
 end
end

def send_message(cell_no, message, short_code)
  Driver.connection.execute("INSERT INTO send_sms (momt, sender, receiver, msgdata, sms_type, smsc_id) VALUES ('MT','"+short_code+"','"+ cell_no+"','"+message+"',2,'"+short_code+"')")
end