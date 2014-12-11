class CabRequestsController < ApplicationController
  include HTTParty
  require 'json'

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

      if params_not_legal(@inc_message) # -1. Check message is empty or not
        @message = "Please enter a cell number and a string"
        send_message(@cell_no, @message, @short_code) # 0. Kick out request if driver already registerd
      elsif(Driver.where("cell_no = ?", @cell_no).present?)
        @message="You are already registered in our system. Thank you!"
        send_message(@cell_no, @message, @short_code)
      elsif(!DriverRegistrationRequest.where("cell_no = ?", @cell_no).present?) # 1. Get Location from the sms      
         @location_to_confirm = driver_register_and_get_location(@cell_no, @inc_message, @short_code)
      else #Already Driver Session initiated
        @driver_reg_session = DriverRegistrationRequest.where("cell_no = ?", @cell_no).first
        locations = @driver_reg_session.location.split("-")
        
        if(locations.present?) #Logic for name input
          locations.each_with_index do |location, index|
            location_name = location.split(",")[0]
            if(location_name.eql? @inc_message)
              @inc_message = index + 1
              break
            end  
          end  
        end  

        if(@inc_message == "1" || @inc_message == "2" || @inc_message == "3")
          locations = @driver_reg_session.location.split("-")
          if(@inc_message.to_i > locations.count)
            @message = "You have chosen wrong input. Please send again correct input"
            send_message(@cell_no, @message, @short_code) # 0. Kick out request if driver send wrong option
          else
            chosen_location = locations[@inc_message.to_i - 1].split(",")
            Driver.create(:cell_no => @cell_no, :location_lat => chosen_location[1],  :location_long =>  chosen_location[2], :location =>  chosen_location[0])
            @driver_reg_session.delete
            @message = "You are registered in the system successfully. Thank you!\nPlease share this info with at least 5 taxi drivers."
            send_message(@cell_no, @message, @short_code)                            
          end  

        elsif(@inc_message == "m" || @inc_message == "M")  
          send_more_locations(@driver_reg_session, @short_code)

        elsif is_no(@inc_message)
          @driver_reg_session.delete
          @message = "Please ask near by people for your location name and send message again"
          send_message(@cell_no, @message, @short_code)                            
        else
          @message = "You have chosen wrong input. Please send again correct input"
          send_message(@cell_no, @message, @short_code)                            
        end

      end  
    end 

    # def receive_sms
    #   @cell_no     = params[:phone]
    #   @inc_message = params[:message]
    #   puts "#{@cell_no} & #{@inc_message}"
    #   render :nothing => true
    # end  

  # http://www.findlatitudeandlongitude.com/batch-geocode/#.VH8IGx9d48o
  # http://www.bulkgeocoder.com/
    # GET /cab_requests/new
    def receive_sms_for_ride(_cell_no, _inc_message, _short_code)
      @cell_no     = _cell_no
      @inc_message = _inc_message
      @short_code  = _short_code

      if params_not_legal(@inc_message)
        @message="Please enter a cell number and a string"
        send_message(@cell_no, @message, @short_code)
      elsif Driver.is_not_driver(@cell_no) # is the call from user?
        if CabRequest.is_new(@cell_no) # new call?
          @location_to_confirm = register_and_get_location(@cell_no, @inc_message) #location to show
          @message = "Please reply y to confirm the location or n for more suggestions"
          send_message(@cell_no, @message, @short_code)
        else # old call
          @cab_request=CabRequest.getCabRequests(@cell_no).where(:status=>false).last #get pending request of this user
          if is_no(@inc_message) # user rejects the location
            if (@cab_request.count < 1) # first time rejection
              @more_location_options = show_more_options(@cab_request) #get more options
              @message = "Please reply with the correct option"
              send_message(@cell_no, @message, @short_code)
            else # on rejection twice. delete the request and show "ask others" message
              @message = "Please ask for the location to other people."
              send_message(@cell_no, @message, @short_code)
              @cab_request.delete 
            end       
          elsif is_option_selected(@inc_message) #if some option has been selected
            lock_choice(@cab_request, @inc_message) #lock the choice (1 to 100)
            contact_nearby_drivers(@cab_request) #contact nearby drivers of the user selected location
            @drivers = show_nearby_drivers(@cab_request) #for testing we will show drivers in ascending order of their nearness.
            @message = "Your request has been forwarded to nearby drivers. Please wait for 7 minutes"
            send_message(@cell_no, @message, @short_code)
          elsif is_yes(@inc_message) #user agrees
            contact_nearby_drivers(@cab_request)
            @drivers = show_nearby_drivers(@cab_request)
            @message = "Your request has been forwarded to nearby drivers. Please wait for 7 minutes"
            send_message(@cell_no, @message, @short_code)
          else
            @message = "You have entered invalid input."
            send_message(@cell_no, @message, @short_code)
          end
        end
      else #if driver
        if is_yes(@inc_message)
          @driver = Driver.where(:cell_no => @cell_no).first
          @driver.confirm_deal
          @message = "Your deal has been confirmed."
          send_message(@cell_no, @message, @short_code)
        elsif is_no(@inc_message)
          @driver  = Driver.where(:cell_no=>params[:user_cell_no]).first.id
          @drivers = ping_next_driver(@driver)
          @message = "Reply with the first driver on the list"
          send_message(@cell_no, @message, @short_code)
        else
          @message="You have entered invalid input."
          send_message(@cell_no, @message, @short_code)
        end

      end  
    end


    # Use callbacks to share common setup or constraints between actions.

    def params_not_legal(message)
      message == "" || message.nil?
    end

    def is_no(message)
      message == "n" || message == "N" || message == "no" || message == "No"
    end

    def is_yes(message)
      message == "y" || message == "Y" || message == "yes" || message == "Yes"
    end

    def is_option_selected(message)
      message.to_i > 0 && message.to_i <= 100
    end

    def register_and_get_location(user_cell_no, location)
      @result =get_locations(location)
      @base   = @result["results"][0] #for first result only
      lat     = get_latitude(@base)
      long    = get_longitude(@base)
      @location_to_confirm = get_location_name(@base)
      @cab_request = CabRequest.new
      @cab_request.register_request(user_cell_no, lat, long, location)
      return @location_to_confirm
    end

    def show_more_options(cab_request)
      cab_request.increment_count #count of location rejection by user
      @result = get_locations(cab_request.location) #get all the locations for a string to show more options
      
      return @result["results"]
    end

    def send_message(cell_no, message, short_code)
      Driver.connection.execute("INSERT INTO send_sms (momt, sender, receiver, msgdata, sms_type, smsc_id) VALUES ('MT','"+short_code+"','"+ cell_no+"','"+message+"',2,'"+short_code+"')")
    end

    def lock_choice(cab_request, choice)
      @result = get_locations(cab_request.location)
      @selected_location = @result["results"][choice.to_i-1]
      lat = get_latitude(@selected_location)
      long = get_longitude(@selected_location)
      location = get_location_name(@selected_location)
      cab_request.lock_choice(lat, long, location)
    end

    def get_locations(user_entered_location)
      # location = user_entered_location #.downcase.split.join('+').delete("'").delete(".").delete(",") #convert string into right form
      if user_entered_location.include? "Arat kilo"
        user_entered_location = "4 Kilo"
      end  
      location = user_entered_location.to_s + " Addis Abab Ethiopia"
      location = location.gsub!(" ", "+")
      @result  = HTTParty.get(URI::encode(API_BASE_URL + location.to_s + APP_KEY))  
      return @result  
    end

    def get_latitude(query_result)
        return query_result["geometry"]["location"]["lat"]
    end

    def get_longitude(query_result)
        return query_result["geometry"]["location"]["lng"]
    end

    def get_location_name(query_result)
      @address_components=query_result["address_components"]
      @location_name = ""
      @address_components.each do |comp|
        @location_name = @location_name+comp["long_name"]+" "
      end
      return @location_name
    end

    def show_nearby_drivers(cab_request)
      @driver_ids = cab_request.driver_ids
      @driver_ids = @driver_ids.split(%r{,\i*})
      @drivers    = Array.new
      @driver_ids.each_with_index do |driver_id, index|
        @drivers[index] = Driver.find(driver_id)
      end
      @drivers = @drivers.first(5)
      return @drivers
    end

    def contact_nearby_drivers(cab_request)
      @drivers = Driver.by_distance(:origin=>[cab_request.latitude, cab_request.longitude]).limit(50)
      @driver_ids = ""
      @drivers.each do |driver_id|
        @driver_ids = @driver_ids+driver_id.id.to_s+","
      end
      @driver_ids = @driver_ids.split(%r{,\i*})
      cab_request.update_attribute(:driver_id, @driver_ids[0])
      # send_message("", )
      @driver_ids = @driver_ids.join(",")
      #insert the new list into cab_request instance
      cab_request.update_attribute(:driver_ids, @driver_ids)
    end

    def ping_next_driver(driver_id)
      @cab_request = CabRequest.where(:driver_id=>driver_id).where(:status=>false).last
      @driver_ids  = @cab_request.driver_ids #get comma seperated ids of drivers
      @driver_ids  = @driver_ids.split(%r{,\i*}) #converts to array
      @driver_ids.shift #pops the first one out
      @cab_request.update_attribute(:driver_id, @driver_ids[0]) #stores the current first id
      @driver_ids  = @driver_ids.join(",") #convert back to comma seperated string
      @cab_request.update_attribute(:driver_ids, @driver_ids) # store the string
      return show_nearby_drivers(@cab_request) #return the list to show
    end

    # For Drivers
    def driver_register_and_get_location(cell_no, searched_location, short_code)
      @result = get_locations(searched_location)

      if(@result['results'].present?)
        # Check if location matchs with google correctly if match register and exit
        @result['results'].each_with_index do |address, index|
          if(index < 2)
            if(searched_location.similar(address["formatted_address"]) >= 85.0)
              Driver.create(:cell_no => cell_no, :location_lat => get_latitude(address), :location_long => get_longitude(address), :location => address["formatted_address"])
              @driver_reg_session = DriverRegistrationRequest.where("cell_no = ?", cell_no).first
              @driver_reg_session.delete
              message="You are registered in the system successfully. Thank you!\nPlease share this info with at least 5 taxi drivers."
              send_message(cell_no, message, short_code)        
              return
            end  
          end  
        end

        # Check if location not matchs with google correctly
        @message  = "Please SMS back the correct number of your location\n"
        @session_message  = ""
        @result['results'].each_with_index do |address, index|
          if(index < 2)
            location = address["address_components"][0]['long_name']
            lat      = get_latitude(address)
            long     = get_longitude(address)
            @message  += (index+1).to_s + "- " + location.to_s + "\n"
            @session_message += location.to_s+","+lat.to_s+","+long.to_s+"-"
          end  
        end

        if(@result['results'].count > 2)
          @message  += "Need more? SMS back M"
        else  
          @message  += "If location not listed? SMS back N"
        end  

        send_message(cell_no, @message, short_code) #Send Message
        DriverRegistrationRequest.create(:cell_no => cell_no, :location => @session_message.gsub( /.{1}$/, '' ), :active => false, :more_location_count => 1, :searched_location => searched_location)


      else # If location is invalid and no result from Google API
        message="Entered location is invalid. Please send again."
        send_message(cell_no, message, short_code)        
      end  

    end

    def send_more_locations(driver_reg_session, short_code)
      @result = get_locations(driver_reg_session.searched_location)
      more_location_count = (driver_reg_session.more_location_count * 2)

      if(@result['results'].count > more_location_count)
        @message  = "Please SMS back the correct number of your location \n"
        @session_message  = ""
        location_count = 1
        @result['results'].each_with_index do |address, index|
          if(index >= (more_location_count - 1) && index < (more_location_count + 1))
            location = address["address_components"][0]['long_name']
            lat      = get_latitude(address)
            long     = get_longitude(address)
            @message  += (location_count).to_s + "- " + location.to_s + "\n"
            @session_message += location.to_s+","+lat.to_s+","+long.to_s+"-"
            location_count += 1
          end  
        end

        if(@result['results'].count > (more_location_count + 2))
          @message  += "Need more? SMS back M"
        else  
          @message  += "If location not listed? SMS back N"
        end  

        send_message(driver_reg_session.cell_no, @message, short_code) #Send Message
        driver_reg_session.update(:location => @session_message.gsub( /.{1}$/, '' ), :more_location_count => (driver_reg_session.more_location_count + 1))

      else
        driver_reg_session.delete
        @message = "No more locations. Please ask near by people for your location name and send message again"
        send_message(@cell_no, @message, @short_code)
      end  
    end  

    def set_cab_request
      @cab_request = CabRequest.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def cab_request_params
      params.require(:cab_request).permit(:location, :latitude, :longitude)
    end

end
