class CabRequestsController < ApplicationController
  include HTTParty
  require 'json'
  before_action :set_cab_request, only: [:show, :edit, :update, :destroy]
  API_BASE_URL = 'https://maps.googleapis.com/maps/api/geocode/json?address='
  APP_KEY= '&key=AIzaSyBe4SyPWoNw_RKyCMK5v_bCD5OE9kvlTGE'

  # GET /cab_requests
  # GET /cab_requests.json
  def index
    @cab_requests = CabRequest.all
  end

  # GET /cab_requests/1
  # GET /cab_requests/1.json
  def show
    # @cab_request = CabRequest.find(params[:id])
    # @message="Your request has been recorded and sent to the nearby driver. Please wait for 7 minutes."
  end

  # GET /cab_requests/new
  def new

    if params[:location] == "" || params[:user_cell_no]== "" || params[:location].nil? || params[:user_cell_no].nil?
      @message="Please enter a cell number and a string"

    elsif Driver.is_not_driver(params[:user_cell_no]) # is the call from user?
      if CabRequest.is_new(params[:user_cell_no]) # new call?
       @location_to_confirm=register_and_get_location(params[:user_cell_no], params[:location]) #location to show
       @message="Please reply y to confirm the location or n for more suggestions"
      else # old call
       @cab_request=CabRequest.getCabRequests(params[:user_cell_no]).where(:status=>false).last #get pending request of this user
       if params[:location]== "n" || params[:location] == "N" # user rejects the location
        if @cab_request.count<1 # first time rejection
         @more_location_options=show_more_options(@cab_request) #get more options
         @message="Please reply with the correct option"
        else # on rejection twice. delete the request and show "ask others" message
          @message="Please ask for the location to other people "
          @cab_request.delete 
        end
       
       elsif params[:location].to_i>0 && params[:location].to_i<=100 #if some option has been selected
         lock_choice(@cab_request, params[:location]) #lock the choice (1 to 100)
         contact_nearby_drivers(@cab_request) #contact nearby drivers of the user selected location
         @drivers=show_nearby_drivers(@cab_request) #for testing we will show drivers in ascending order of their nearness.
         @message="your request has been forwarded to nearby drivers. Please wait for 7 minutes"
      
       elsif params[:location]== "y" || params[:location] == "Y" #user agrees
         contact_nearby_drivers(@cab_request)
         @drivers=show_nearby_drivers(@cab_request)
         @message="your request has been forwarded to nearby drivers. Please wait for 7 minutes"
  
       else
         @message="Command unknown."
       end
     end

  else #if driver
    if params[:location]=="y" || params[:location]=="Y" 
      @driver=Driver.where(:cell_no=>params[:user_cell_no]).first
      @driver.confirm_deal
      @message="your deal has been confirmed."
    elsif(params[:location]=="n" || params[:location]=="N")
      @driver=Driver.where(:cell_no=>params[:user_cell_no]).first.id
      @drivers=ping_next_driver(@driver)
      @message="Reply with the first driver on the list"
    else
      @message="Command unknown."
    end

  end
  end

  # GET /cab_requests/1/edit
  def edit
  end

  # POST /cab_requests
  # POST /cab_requests.json
  def create
    respond_to do |format|
      if @cab_request.save
        format.html { redirect_to @cab_request, notice: 'Cab request was successfully created.' }
        format.json { render :show, status: :created, location: @cab_request }
      else
        format.html { render :new }
        format.json { render json: @cab_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cab_requests/1
  # PATCH/PUT /cab_requests/1.json
  def update
    respond_to do |format|
      if @cab_request.update(cab_request_params)
        format.html { redirect_to @cab_request, notice: 'Cab request was successfully updated.' }
        format.json { render :show, status: :ok, location: @cab_request }
      else
        format.html { render :edit }
        format.json { render json: @cab_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cab_requests/1
  # DELETE /cab_requests/1.json
  def destroy
    @cab_request.destroy
    respond_to do |format|
      format.html { redirect_to cab_requests_url, notice: 'Cab request was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.

    def register_and_get_location(user_cell_no, location)
       @result=get_locations(location)
       @base=@result["results"][0] #for first result only
       lat=get_latitude(@base)
       long=get_longitude(@base)
       @location_to_confirm=get_location_name(@base)
       @cab_request = CabRequest.new
       @cab_request.register_request(user_cell_no, lat, long, location)
       return @location_to_confirm
    end

    def show_more_options(cab_request)
      cab_request.increment_count #count of location rejection by user
      @result=get_locations(cab_request.location) #get all the locations for a string to show more options
      
      return @result["results"]
    end

    def lock_choice(cab_request, choice)
      @result=get_locations(cab_request.location)
      @selected_location=@result["results"][choice.to_i-1]
      lat=get_latitude(@selected_location)
      long=get_longitude(@selected_location)
      location=get_location_name(@selected_location)
      cab_request.lock_choice(lat, long, location)
    end

    def get_locations(user_entered_location)
      location=user_entered_location.downcase.split.join('+').delete("'").delete(".").delete(",") #convert string into right form
      @result=HTTParty.get(API_BASE_URL+location.to_s+APP_KEY)  
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
      @location_name=""
      @address_components.each do |comp|
        @location_name=@location_name+comp["long_name"]+" "
      end
      return @location_name
    end

    def show_nearby_drivers(cab_request)
      @driver_ids=cab_request.driver_ids
      @driver_ids=@driver_ids.split(%r{,\i*})
      @drivers=Array.new
      for i in 0..4
        @drivers[i]=Driver.find(@driver_ids[i])
      end
      return @drivers
    end

    def contact_nearby_drivers(cab_request)
      @drivers=Driver.by_distance(:origin=>[cab_request.latitude, cab_request.longitude]).limit(50)
      @driver_ids=""
      @drivers.each do |driver_id|
        @driver_ids=@driver_ids+driver_id.id.to_s+","
      end
      @driver_ids=@driver_ids.split(%r{,\i*})
      cab_request.update_attribute(:driver_id, @driver_ids[0])
      @driver_ids=@driver_ids.join(",")
      #send message to the first driver
      #insert the new list into cab_request instance
      cab_request.update_attribute(:driver_ids, @driver_ids)
    end

    def ping_next_driver(driver_id)
      @cab_request=CabRequest.where(:driver_id=>driver_id).where(:status=>false).last
      @driver_ids=@cab_request.driver_ids #get comma seperated ids of drivers
      @driver_ids=@driver_ids.split(%r{,\i*}) #converts to array
      @driver_ids.shift #pops the first one out
      @cab_request.update_attribute(:driver_id, @driver_ids[0]) #stores the current first id
      @driver_ids=@driver_ids.join(",") #convert back to comma seperated string
      @cab_request.update_attribute(:driver_ids, @driver_ids) # store the string
      return show_nearby_drivers(@cab_request) #return the list to show
    end

    # def driver_available(driver)
    #   #send message on driver.cell_no
    #   @available=true
    #   binding.pry
    #   return @available
    # end
    # def confirm_location(location)
    #   confirmed= true
    #   puts "your selected location is: " + location +". Do you confirm?"
    #   binding.pry
    #   return confirmed
    # end

    # def select_a_location(locations) 
    #   @choice=1.to_i
    #   locations.each_with_index do |x, index|
    #   puts "#{index}-"+ locations[index]["address_components"][0]["long_name"]
    #   end
    #   binding.pry
    #   return @choice
    # end

    def set_cab_request
      @cab_request = CabRequest.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def cab_request_params
      params.require(:cab_request).permit(:location, :latitude, :longitude)
    end
end
