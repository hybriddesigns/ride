class CabRequestsController < ApplicationController
  include HTTParty
  require 'json'
  before_action :set_cab_request, only: [:show, :edit, :update, :destroy]

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

    if is_user(params[:user_cell_no])
      if is_new(params[:user_cell_no])
       @cab_request = CabRequest.new
       @cab_request.user_cell_no=params[:user_cell_no]
       @cab_request.status=false
       @cab_request.broadcast=false
       @cab_request.count=0.to_i
       @result=HTTParty.get('https://maps.googleapis.com/maps/api/geocode/json?address='+params[:location]+'&key=AIzaSyBe4SyPWoNw_RKyCMK5v_bCD5OE9kvlTGE')
       @location_to_confirm=@result["results"][0]["address_components"][0]["long_name"]
       @cab_request.latitude=@result["results"][0]["geometry"]["location"]["lat"]
       @cab_request.longitude=@result["results"][0]["geometry"]["location"]["lng"]
       @cab_request.location=@location_to_confirm
       @cab_request.save
     else
       @cab_request=CabRequest.where(:user_cell_no=>params[:user_cell_no]).last
       if params[:location]== "n"
        if @cab_request.count<1

         @count=@cab_request.count+1
         @cab_request.update_attribute(:count, @count)
         @result=HTTParty.get('https://maps.googleapis.com/maps/api/geocode/json?address='+@cab_request.location+'&key=AIzaSyBe4SyPWoNw_RKyCMK5v_bCD5OE9kvlTGE')
         @result["results"]
        else
          @ask_user_message="Please ask for the location to other people "
          @cab_request.delete
        end
       end

       elsif params[:location].to_i>=0 && params[:location].to_i<=20
         @result=HTTParty.get('https://maps.googleapis.com/maps/api/geocode/json?address='+@cab_request.location+'&key=AIzaSyBe4SyPWoNw_RKyCMK5v_bCD5OE9kvlTGE')
         @location=@result["results"][params[:location]]
         @cab_request.update_attribute(:location, @location["address_components"][0]["long_name"])
         @cab_request.update_attribute(:latitude, @location["geometry"]["location"]["lat"])
         @cab_request.update_attribute(:longitude, @location["geometry"]["location"]["lng"])
         @cab_request.update_attribute(:status, false)
         @cab_request.time_limit=Time.now+7.minutes
         @drivers=Driver.by_distance(:origin=>[cab_request.latitude, cab_request.longitude]).limit(5)
         #send message to first driver
         @drivers.each_with_index do |x,index|
          @driver_list=DriverList.new
          @driver_list.driver_id=x.id
          @driver_list.user_cell_no=@cab_request.user_cell_no
          @driver_list.deletion_time=Time.now(index+1)
          @driver.save
        end

       elsif params[:location]== "y"
         @cab_request.update_attribute(:status, false)
         @cab_request.time_limit=Time.now+7.minutes
         @drivers=Driver.by_distance(:origin=>[cab_request.latitude, cab_request.longitude]).limit(5)
         #send message to first driver
         @drivers.each_with_index do |x,index|
          @driver_list=DriverList.new
          @driver_list.driver_id=x.id
          @driver_list.user_cell_no=@cab_request.user_cell_no
          @driver_list.deletion_time=Time.now(index+1)
          @driver.save
        end
       else
         @error_message="Command not known"
       end

     end
         
    end

  else
    if(params[:location]=="y")
      @cab_request=CabRequest.where(:user_cell_no=>params[:user_cell_no]).last
      @driver=Driver.where(:cell_no=>params[:driver_cell_no]).first
      @drivers=@cab_request.driver_lists
      if @drivers.present? && @drivers.where(:id=>@driver.id)
        @drivers.delete_all
        @cab_request.update_attribute(:status, true)
        @cab_request.driver_id=@driver.id
      else

      end
    end


    # if params[:location] == "Next"

    # @cab_request = CabRequest.new
    # @cab_request.user_cell_no=params[:user_cell_no]
    # @result=HTTParty.get('https://maps.googleapis.com/maps/api/geocode/json?address='+params[:location]+'&key=AIzaSyBe4SyPWoNw_RKyCMK5v_bCD5OE9kvlTGE')
    # @confirm_location=@result["results"][0]["address_components"][0]["long_name"]
    # @location=@result["results"][0]
    
    # if confirm_location(@confirm_location)
    #    @cab_request.location=@location["address_components"][0]["long_name"]
    #    @cab_request.latitude=@location["geometry"]["location"]["lat"]
    #    @cab_request.longitude=@location["geometry"]["location"]["lng"]

    # elsif @result["results"].size > 1
    #   @choice=select_a_location(@result["results"])
    #   @location=@result["results"][@choice]
    #   if @location.present?
    #     @cab_request.location=@location["address_components"][0]["long_name"]
    #     @cab_request.latitude=@location["geometry"]["location"]["lat"]
    #     @cab_request.longitude=@location["geometry"]["location"]["lng"]
    #   end
    # else

    # end
  end

  # GET /cab_requests/1/edit
  def edit
  end

  # POST /cab_requests
  # POST /cab_requests.json
  def create
    # @cab_request = CabRequest.new
    # @cab_request.location=params["location"]
    # @cab_request.latitude=params["latitude"]
    # @cab_request.longitude=params["longitude"]
    # @cab_request.user_cell_no=params["user_cell_no"]

    # find_nearby_drivers(@cab_request)

    # respond_to do |format|
    #   if @cab_request.save
    #     format.html { redirect_to @cab_request, notice: 'Cab request was successfully created.' }
    #     format.json { render :show, status: :created, location: @cab_request }
    #   else
    #     format.html { render :new }
    #     format.json { render json: @cab_request.errors, status: :unprocessable_entity }
    #   end
    # end
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

    def is_new(cell_no)
      @user=CabRequest.where(:user_cell_no=> cell_no)
      @new=CabRequest.where(:status => false)
      if @new.present?
        return false
      else
        return true
      end
    end

    def is_user(cell_no)
      @driver=Driver.where(:cell_no=>cell_no).last
      if @driver.present?
        return false
      else
        return true
      end
    end


    def find_nearby_drivers(cab_request)
    @drivers=Driver.by_distance(:origin=>[cab_request.latitude, cab_request.longitude]).limit(5)
    @available=false
    @drivers.each do |x|
      @available=driver_available(x)
      if @available
        cab_request.update_attribute(:driver_id, x.id)
        break
      end
    end
    end


    def driver_available(driver)
      #send message on driver.cell_no
      @available=true
      binding.pry
      return @available
    end
    def confirm_location(location)
      confirmed= true
      puts "your selected location is: " + location +". Do you confirm?"
      binding.pry
      return confirmed
    end

    def select_a_location(locations) 
      @choice=1.to_i
      locations.each_with_index do |x, index|
      puts "#{index}-"+ locations[index]["address_components"][0]["long_name"]
      end
      binding.pry
      return @choice
    end

    def set_cab_request
      @cab_request = CabRequest.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def cab_request_params
      params.require(:cab_request).permit(:location, :latitude, :longitude)
    end
end
