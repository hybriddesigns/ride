class CabRequestsController < ApplicationController
  include HTTParty
  require 'json'
  before_action :authenticate_user!, :only => [:new]
  API_BASE_URL = 'https://maps.googleapis.com/maps/api/geocode/json?address='
  APP_KEY= '&key=AIzaSyBe4SyPWoNw_RKyCMK5v_bCD5OE9kvlTGE'

  def receive_sms
    cell_no     = params[:phone]
    inc_message = params[:message]
    short_code  = params[:shortcode]
    

    if(short_code == "+2518812")
      receive_sms_for_driver_registration(cell_no, inc_message, "8812")
    elsif(short_code == "+2518202")
      receive_sms_for_ride(cell_no, inc_message, "8202")
    end  
    puts "#{@cell_no} & #{@inc_message}"
    render :nothing => true
  end  

  private

    # -1. Check message is empty or not -Done
    # 0. Kick out request if driver already registerd -Done
    # 1. Get Location from the sms -Done
    # 2. Pass to google API and get 3 response back and send sms -Done
    # 3. If driver replies with (1,2,3) then store that address. -Done
    # 4. If driver replies with (n) then kill session -Done
    # 5. If not then ask him to ask near peoples for correct place name -Done
    # 6. Process location sms again -Done
    # 7. If location matchs then register driver with lat longs -Done


    def receive_sms_for_driver_registration(_cell_no, _inc_message, _short_code)
      @cell_no     = _cell_no
      @inc_message = _inc_message
      @short_code  = _short_code

      if (@inc_message == "" || nil) # -1. Check message is empty or not
        @message = "Please SMS your location."
        send_message(@cell_no, @message, @short_code) # 0. Kick out request if driver already registerd
      elsif(Driver.where("cell_no = ?", @cell_no).present?)
        @message="You are already registered in our system. Thank you!"
        send_message(@cell_no, @message, @short_code)
      elsif(!DriverRegistrationRequest.where(:deleted => false, :cell_no => @cell_no).present?) # 1. Get Location from the sms      
         @location_to_confirm = driver_register_and_get_location(@cell_no, @inc_message, @short_code)
      else #Already Driver Session initiated
        @driver_reg_session = DriverRegistrationRequest.where(:deleted => false, :cell_no => @cell_no).first
        locations = @driver_reg_session.location.split("-")
        
        if(locations.present?) #Logic for name input
          locations.each_with_index do |location, index|
            location_name = location.split(",")[0]
            if(location_name.casecmp(@inc_message.strip) == 0) #string compare regardless of string case
              @inc_message = (index + 1).to_s
              break
            end  
          end  
        end  

        if(@inc_message == "1" || @inc_message == "2" || @inc_message == "3" || @inc_message == 1 || @inc_message == 2 || @inc_message == 3)
          locations = @driver_reg_session.location.split("-")
          if(@inc_message.to_i > locations.count)
            @message = "Please SMS back the right spelling from the given list or simply SMS back the number corresponding to your choice."
            send_message(@cell_no, @message, @short_code) # 0. Kick out request if driver send wrong option
          else
            chosen_location = locations[@inc_message.to_i - 1].split(",")
            Driver.create(:cell_no => @cell_no, :location_lat => chosen_location[1],  :location_long =>  chosen_location[2], :location =>  chosen_location[0])
            @driver_reg_session.update_attributes(:active => true, :deleted => true)
            @message = "You are registered in the system successfully. Thank you!\nPlease share this info with at least 5 taxi drivers."
            send_message(@cell_no, @message, @short_code)                            
          end  

        elsif(@inc_message == "m" || @inc_message == "M")  
          send_more_locations(@driver_reg_session, @short_code)

        elsif is_no(@inc_message)
          @driver_reg_session.update_attributes(:deleted => true)
          @message = "Please ask near by people the correct spelling to your location and send message again"
          send_message(@cell_no, @message, @short_code)                            

        else
          @message = "Please SMS back the right spelling from the given list or simply SMS back the number corresponding to your choice."
          send_message(@cell_no, @message, @short_code)                            
        end

      end  
    end 

    def receive_sms_for_ride(_cell_no, _inc_message, _short_code)
      @cell_no     = _cell_no
      @inc_message = _inc_message
      @short_code  = _short_code

      # @message = "Our system is under development and will complete in a week. Please try later."
      # send_message(@cell_no, @message, @short_code)
      # return

      if (@inc_message == "" || nil) # -1. Check message is empty or not
        @message = "Please SMS your location."
        send_message(@cell_no, @message, @short_code) # 0. Kick out request if driver already registerd
      
      elsif Driver.is_not_driver(@cell_no) # is the call from user?

        #Auction Case
        @last_cab_request = CabRequest.where(:customer_cell_no => @cell_no, :ordered => true).last #get last request of this user
        if((@last_cab_request.present?) && (@inc_message == "Next" || @inc_message == "NEXT" || @inc_message == "next"))
          @last_cab_request.update_attributes(:broadcast => true)
          @message = 'Sorry for the delay! Looks like our drivers are busy assisting other customers. We have put your number in priority considering the delay.'
          send_message(@cell_no, @message, @short_code)
          return
        end  
        #Auction Case

        if CabRequest.is_new(@cell_no) # new call?
          register_customer_and_get_location(@cell_no, @inc_message, @short_code) #location to show
        else # old call
          @cab_request = CabRequest.where(:deleted => false, :customer_cell_no => @cell_no, :status => false).last #get pending request of this user
          if(@cab_request.more_location_count > 0)
            locations = @cab_request.more_locations.split("-")          
            if(locations.present?) #Logic for name input
              locations.each_with_index do |location, index|
                location_name = location.split(",")[0]
                if(location_name.casecmp(@inc_message.strip) == 0) #string compare regardless of string case
                  @inc_message = (index + 1).to_s
                  break
                end  
              end  
            end  
          end  

          if is_no(@inc_message) # user rejects the location
            if(@cab_request.location_selected)
              @message = "Your RIDE request is canceled. Please come back and visit us later."
              send_message(@cell_no, @message, @short_code)
              @cab_request.update_attributes(:deleted => true)
            # elsif (!@cab_request.options_flag) # first time rejection
            #   send_more_locations_to_customer(@cab_request, @short_code) #send more options
            else # on rejection twice. delete the request and show "ask others" message
              send_more_locations_to_customer(@cab_request, @short_code) #send more options
              # @message = "Please ask near by people the correct spelling to your location and send message again, Or try different name to the location"
              # send_message(@cell_no, @message, @short_code)
              # @cab_request.update_attributes(:deleted => true)
            end       

          elsif (is_yes(@inc_message) && @cab_request.more_location_count == 0) #user agrees
            #Add Terms & Conditions
            @cab_request.update_attributes(:location_selected => true)
            @message = 'Your RIDE is being arranged now. To COMPLETE ur order, If u agree to our terms, SMS Back A. To read our terms, SMS T before u complete the order.'
            send_message(@cell_no, @message, @short_code)

          # elsif ((@cab_request.ordered) && (@inc_message == "Next" || @inc_message == "NEXT" || @inc_message == "next"))
          #   @cab_request.update_attributes(:broadcast => true)
          #   @message = 'Sorry for the delay! Looks like our drivers are busy assisting other customers. We have put your number in priority considering the delay.'
          #   send_message(@cell_no, @message, @short_code)

          elsif ((@inc_message == "1" || @inc_message == "2" || @inc_message == "3" || @inc_message == 1 || @inc_message == 2 || @inc_message == 3) && @cab_request.more_locations.present?) #if some option has been selected
            lock_location_choice_for_ride(@cab_request, @inc_message, @short_code) #lock the choice (1 to 100)

          elsif(@cab_request.location_selected)
            if(@inc_message == "A" || @inc_message == "a")
              @cab_request.update_attributes(:ordered => true)
              contact_nearby_drivers(@cab_request)
              @message = 'Congrats! Your request is sent to a nearby taxi. If you do not get a call within 7 mins, please SMS next.'
              send_message(@cell_no, @message, @short_code)
            elsif(@inc_message == "t" || @inc_message == "T")
              @message = 'Terms| by completing order u agree that we pass ur phone no. to a Taxi service provider, and upon Court order to authorities if requested. Sms m for more...'
              send_message(@cell_no, @message, @short_code)
            elsif(@inc_message == "m" || @inc_message == "M")
              @message = 'Ride doesn\'t employ any taxi driver and Is not liable to driver\'s actions but we\'ll fully cooperate with legal authorities to resolve any issue. SMS A if u agree to term'
              send_message(@cell_no, @message, @short_code)
            else
              @message = 'Please SMS A to complete order or N to cancel'
              send_message(@cell_no, @message, @short_code)
            end  

          else
            @message = "Please ask near by people the correct spelling to your location and send message again, Or try different name to the location"
            send_message(@cell_no, @message, @short_code)
            @cab_request.update_attributes(:closed => true, :deleted => true) 
          end
        end
      
      else #if driver
        @driver = Driver.where(:cell_no => @cell_no).first
        if !@inc_message.empty?
          @cab_request  = CabRequest.where(:deleted => false, :current_driver_id => @driver.id, :status => false).last
          if @cab_request.present?
            @message = "Here we go... Your customer lives near "+@cab_request.location.to_s+". You must call him/her in 2 mins. Customer phone number: "+@cab_request.customer_cell_no.to_s
            send_message(@driver.cell_no, @message, @short_code)
            @cab_request.update_attributes(:status => true, :final_driver_id => @driver.id, :deleted => true)
          elsif (!present_in_broadcasted_drivers(@driver)) 
            @message = "Ops, sorry someone got the number before you. Next time text back a bit faster."
            send_message(@driver.cell_no, @message, @short_code) 
          end
        elsif is_no(@inc_message)
          @message = "Your turn is given to another driver. Thank you for helping another fellow RIDE driver :)"
          send_message(@driver.cell_no, @message, @short_code)
          ping_next_driver(@driver.id, @short_code)          
        else
          @message = "Sorry you replied late! In the future, when you get a request reply back in ONE minute. Otherwise the system automatically skips your turn."
          send_message(@driver.cell_no, @message, @short_code)
        end
      end  

    end


    # Use callbacks to share common setup or constraints between actions.
    def is_no(message)
      message == "n" || message == "N" || message == "no" || message == "No"
    end

    def is_yes(message)
      message == "y" || message == "Y" || message == "yes" || message == "Yes"
    end

    def is_option_selected(message)
      message.to_i > 0 && message.to_i <= 100
    end

    def register_customer_and_get_location(customer_cell_no, location, short_code)
      @results = get_locations(location)
      if(@results.count > 0)
        @base   = @results[0] #for first result only
        lat     = @base['lat']
        long    = @base['long']
        @location_to_confirm = @base['name']
        @cab_request = CabRequest.new
        @cab_request.register_request(customer_cell_no, lat, long, location)
        @message   = "Is your pick-up location '"+@location_to_confirm+"?' SMS Y for Yes, N for No"
        send_message(customer_cell_no, @message, short_code)        
      else # If location is invalid and no result from Google API
        @message = "Please ask near by people the correct spelling to your location and send message again"
        send_message(customer_cell_no, @message, short_code)        
      end  
    end

    def send_more_locations_to_customer(cab_request, short_code)
      @results = get_locations(cab_request.location) #get all the locations for a string to show more options
      more_location_count = (cab_request.more_location_count * 2)

      if(@results.count > (more_location_count+1))
        @message  = "Please SMS back the correct number of your location\n"
        @session_message  = ""
        location_count = 1
        @results.each_with_index do |result, index|
          if(index >= (more_location_count+1) && location_count < 3)
            location = result['name']
            lat      = result['lat']
            long     = result['long']
            @message += (location_count).to_s + "- " + location.to_s + "\n"
            @session_message += location.to_s+","+lat.to_s+","+long.to_s+"-"
            location_count   += 1
          end  
        end
        cab_request.update_attributes(:more_locations => @session_message.gsub( /.{1}$/, '' ) , :more_location_count => (cab_request.more_location_count + 1))
        @message  += "If location not listed? SMS back N"
        send_message(cab_request.customer_cell_no, @message, short_code) #Send Message
      else
        @message = "Please ask near by people the correct spelling to your location and send message again, Or try different name to the location"
        send_message(cab_request.customer_cell_no, @message, @short_code)
        cab_request.update_attributes(:closed => true, :deleted => true)
      end  

    end

    def send_message(cell_no, message, short_code)
      Driver.connection.execute("INSERT INTO send_sms (momt, sender, receiver, msgdata, sms_type, smsc_id) VALUES (\"MT\",\""+short_code+"\",\""+ cell_no+"\",\""+message+"\",2,\""+short_code+"\")")
    end

    def lock_location_choice_for_ride(cab_request, choice, short_code)
      locations = cab_request.more_locations.split("-")
      if(choice.to_i > locations.count)
        @message = "Please ask near by people the correct spelling to your location and send message again, Or try different name to the location"
        send_message(cab_request.customer_cell_no, @message, short_code) # 0. Kick out request if driver send wrong option
        cab_request.update_attributes(:closed => true, :deleted => true)
      else
        chosen_location = locations[choice.to_i - 1].split(",")
        cab_request.lock_choice(chosen_location[1], chosen_location[2], chosen_location[0]) # lat, long, location
        #Add Terms & Conditions
        @message = 'Your RIDE is being arranged now. To COMPLETE ur order, If u agree to our terms, SMS Back A. To read our terms, SMS T before u complete the order.'
        send_message(@cell_no, @message, @short_code)
      end  
    end

    def contact_nearby_drivers(cab_request)
      @drivers = Driver.within(1, :units => :miles, :origin => [cab_request.latitude, cab_request.longitude])
      #Testing
      # @drivers = Driver.where("cell_no IN ('+251929104455', '+251913135534', '+251938483821')")
      #Testing
      @drivers_ids = ""

      if(@drivers.present?)
        @drivers.each_with_index do |driver, index|
          if(index > 0) #Skip first as we have already popped out from list  
            @drivers_ids += driver.id.to_s+","
          end  
        end  
        #Send message to first driver
        @message = "Surprise! We found you a new taxi customer. Would you like to take the request? SMS 'Y' for Yes, 'N' for No"
        send_message(@drivers.first.cell_no, @message, @short_code)        
        cab_request.update_attributes(:current_driver_id => @drivers.first.id, :chosen_drivers_ids => @drivers_ids.gsub(/.{1}$/, ''), :offer_count => (cab_request.offer_count+1))
      else #If driver not available in the locality
        @message = "All our drivers are busy at this time assisting other customers. Please try again in a few mins. FYI: We are registering more drivers now."
        send_message(@cell_no, @message, @short_code)   
        cab_request.update_attributes(:closed => true, :deleted => true)       
      end  
    end

    def ping_next_driver(driver_id, short_code)
      @cab_request  = CabRequest.where(:deleted => false, :current_driver_id => driver_id, :status => false).last
      @drivers_ids  = @cab_request.chosen_drivers_ids #get comma seperated ids of drivers
      if(!@drivers_ids.empty?)
        @drivers_ids  = @drivers_ids.split(",") #converts to array
        current_driver = Driver.find(@drivers_ids[0]) #Pick next driver
        @drivers_ids.shift #pops the first one out
        @drivers_ids  = @drivers_ids.join(",") #convert back to comma seperated string
        @cab_request.update_attributes(:current_driver_id => current_driver.id, :chosen_drivers_ids => @drivers_ids, :offer_count => (@cab_request.offer_count+1)) #stores the current first id
        @message = "Surprise! We found you a new taxi customer. Would you like to take the request? SMS 'Y' for Yes, 'N' for No"
        send_message(current_driver.cell_no, @message, short_code)        
      else
        @message = "All our drivers are busy at this time assisting other customers. Please try again in a few mins. FYI: We are registering more drivers now."
        send_message(@cab_request.customer_cell_no, @message, short_code)        
        @cab_request.update_attributes(:closed => true, :deleted => true)
      end
    end

    # For Drivers
    def driver_register_and_get_location(cell_no, searched_location, short_code)
      @results = get_locations(searched_location)

      if(@results.present?)
        # Check if location matchs with google correctly if match register and exit
        @results.each_with_index do |result, index|
          if(index < 2)
            if(searched_location.similar(result['name']) >= 85.0)
              Driver.create(:cell_no => cell_no, :location_lat => result['lat'], :location_long => result['long'], :location => result['name'])
              @driver_reg_session = DriverRegistrationRequest.where(:deleted => false, :cell_no => cell_no).first
              @driver_reg_session.update_attributes(:active => true, :deleted => true)
              message="You are registered in the system successfully. Thank you!\nPlease share this info with at least 5 taxi drivers."
              send_message(cell_no, message, short_code)        
              return
            end  
          end  
        end

        # Check if location not matchs with google correctly
        @message  = "Please SMS back the correct number of your location\n"
        @session_message  = ""
        @results.each_with_index do |result, index|
          if(index < 2)
            location = result['name']
            lat      = result['lat']
            long     = result['long']
            @message  += (index+1).to_s + "- " + location.to_s + "\n"
            @session_message += location.to_s+","+lat.to_s+","+long.to_s+"-"
          end  
        end

        if(@results.count > 2)
          @message  += "Need more? SMS back M"
        else  
          @message  += "If location not listed? SMS back N"
        end  

        send_message(cell_no, @message, short_code) #Send Message
        DriverRegistrationRequest.create(:cell_no => cell_no, :location => @session_message.gsub( /.{1}$/, '' ), :active => false, :more_location_count => 1, :searched_location => searched_location, :deleted => false)


      else # If location is invalid and no result from Google API
        message = "Please ask near by people the correct spelling to your location and send message again"
        send_message(cell_no, message, short_code)        
      end  

    end

    def send_more_locations(driver_reg_session, short_code)
      @results = get_locations(driver_reg_session.searched_location)
      more_location_count = (driver_reg_session.more_location_count * 2)

      if(@results.count > more_location_count)
        @message  = "Please SMS back the correct number of your location \n"
        @session_message  = ""
        location_count = 1
        @results.each_with_index do |result, index|
          if(index >= (more_location_count - 1) && index < (more_location_count + 1))
            location = result['name']
            lat      = result['lat']
            long     = result['long']
            @message  += (location_count).to_s + "- " + location.to_s + "\n"
            @session_message += location.to_s+","+lat.to_s+","+long.to_s+"-"
            location_count += 1
          end  
        end

        if(@results.count > (more_location_count + 2))
          @message  += "Need more? SMS back M"
        else  
          @message  += "If location not listed? SMS back N"
        end  

        send_message(driver_reg_session.cell_no, @message, short_code) #Send Message
        driver_reg_session.update(:location => @session_message.gsub( /.{1}$/, '' ), :more_location_count => (driver_reg_session.more_location_count + 1))

      else
        driver_reg_session.update_attributes(:deleted => true)
        @message = "No more locations. Please ask near by people the correct spelling to your location and send message again"
        send_message(@cell_no, @message, @short_code)
      end  
    end  

    def present_in_broadcasted_drivers(driver)
      @cab_requests = CabRequest.where(:deleted => false, :status => false, :broadcast => true)
      @cab_request  = nil #the cab request needed
      @cab_requests.each do |cab_request|
        @drivers_ids  = cab_request.chosen_drivers_ids #get comma seperated ids of drivers
         if(!@drivers_ids.empty?)
           @drivers_ids  = @drivers_ids.split(",") #converts to array
           @drivers_ids.each do |driver_id|                  
             if (driver.id == driver_id.to_i)
               @cab_request = cab_request
               break
             end
           end
         end
      end

      if @cab_request.present?
        @message = "Here we go... Your customer lives near "+@cab_request.location.to_s+". You must call him/her in 2 mins. Customer phone number: "+@cab_request.customer_cell_no.to_s
        send_message(driver.cell_no, @message, @short_code) 
        @cab_request.update_attributes(:status => true, :final_driver_id => driver.id, :deleted => true)
        return true
      else
        return false
      end
    end

    ######### Methods Related To Location API #########
    def get_locations(user_entered_location)
      if user_entered_location.include? "Arat kilo"
        user_entered_location = "4 Kilo"
      end  
      location = user_entered_location.to_s + " Addis Ababa Ethiopia"
      location = location.gsub!(" ", "+")
      @google_locations  = HTTParty.get(URI::encode(API_BASE_URL + location.to_s + APP_KEY))
      #Get Results from Google
      @result = Array.new
      @google_location_names = Array.new
      @google_locations['results'].each do |google_location|
        if(google_location['address_components'][0]['long_name'] != "Addis Ababa")
          location = Hash.new
          location['name'] = google_location['address_components'][0]['long_name']
          location['lat']  = google_location['geometry']['location']['lat']
          location['long'] = google_location['geometry']['location']['lng']
          @google_location_names.push(location['name'])
          @result.push(location)
        end  
      end  
      binding.pry
      #Get Results from system
      @sys_locations = Location.where("location_name Like '%#{user_entered_location}%'")
      @sys_locations.each do |sys_location|
        if(! @google_location_names.include? sys_location.location_name)
          location = Hash.new
          location['name'] = sys_location.location_name
          location['lat']  = sys_location.latitude
          location['long'] = sys_location.longitude
          @result.push(location)
        end 
      end  
      return @result  
    end
    ######### Methods Related To Location API #########
end
