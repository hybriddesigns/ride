namespace :events do

  desc "Rake task to manage ride requests"
  task :fetch => :environment do
 
    @short_code   = "+2518202"
    @passed_time  = Time.now - 5.minutes

    puts "Check cab requests of 5 minutes old and not responded. Broadcasting to near drivers" 
    puts (Time.now).to_s + @passed_time.to_s

    @cab_requests = CabRequest.where(:status => false, :broadcast => true, :ordered => true).where("created_at < ?", @passed_time)
    @cab_requests.each do |cab_request|
    	#send broadcast to all remaining drivers
      @drivers_ids  = cab_request.chosen_drivers_ids
      if @drivers_ids.present?
      	cab_request.update_attribute(:broadcast, true)
        @drivers_ids = @drivers_ids.split(",")
        @drivers_ids.each do |driver_id|
          @driver  = Driver.find(driver_id)
          @message = "Hurry a customer is waiting for a RIDE. We have sent this request to 20 drivers. First one to text Y gets the phone number of the customer." 
          send_message(@driver.cell_no, @message, @short_code)#send message to @driver.cell_no
        end
      else
        @message = "All our drivers are busy at this time assisting other customers. Please try again in a few mins. FYI: We are registering more drivers now."
        send_message(cab_request.customer_cell_no, @message, @short_code)
        cab_request.delete
      end
    end

    @passed_time  = Time.now - 1.minutes
    puts "Check cab requests of 1 minutes and not responded by the chosen driver" 
    puts (Time.now).to_s + @passed_time.to_s

    @cab_requests = CabRequest.where(:status=>false, :broadcast=>false, :ordered => true).where("updated_at < ?", @passed_time)
    @cab_requests.each do |cab_request|
      if(cab_request.offer_count == 5)
        cab_request.update_attribute(:broadcast => true)        
      elsif cab_request.chosen_drivers_ids.present?  
      	@driver_ids = cab_request.chosen_drivers_ids
      	@driver_ids = @driver_ids.split(%r{,\i*})
        @current_driver_id = @driver_ids.first
        @current_driver = Driver.find(@current_driver_id)
        @message = "Surprise! We found you a new taxi customer. Would you like to take the request? SMS 'Y' for Yes, 'N' for No"
        send_message(@current_driver.cell_no, @message, @short_code)
        @driver_ids.delete_at(0)
        @driver_ids = @driver_ids.join(",")
        cab_request.update_attributes(:current_driver_id => @current_driver_id, :chosen_drivers_ids => @driver_ids)
      else
        @message = "All our drivers are busy at this time assisting other customers. Please try again in a few mins. FYI: We are registering more drivers now."
        send_message(cab_request.customer_cell_no, @message, @short_code)
        cab_request.delete
      end
    end

    @passed_time  = Time.now - 1.hours
    puts "Check cab requests 1 hours old and remove them" 
    puts (Time.now).to_s + @passed_time.to_s

    @cab_requests = CabRequest.where(:ordered => false).where("updated_at < ?", @passed_time)
    @cab_requests.each do |cab_request|
      @message = "Your request at ride is canceled because you took an hour to reply. To order again, pls SMS your location."
      send_message(cab_request.customer_cell_no, @message, @short_code)
      cab_request.delete
    end

  end
end

def send_message(cell_no, message, short_code)
  Driver.connection.execute("INSERT INTO send_sms (momt, sender, receiver, msgdata, sms_type, smsc_id) VALUES ('MT','"+short_code+"','"+ cell_no+"','"+message+"',2,'"+short_code+"')")
end