require 'test_helper'

class CabRequestsControllerTest < ActionController::TestCase
  setup do
    @cab_request = cab_requests(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:cab_requests)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create cab_request" do
    assert_difference('CabRequest.count') do
      post :create, cab_request: {  }
    end

    assert_redirected_to cab_request_path(assigns(:cab_request))
  end

  test "should show cab_request" do
    get :show, id: @cab_request
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @cab_request
    assert_response :success
  end

  test "should update cab_request" do
    patch :update, id: @cab_request, cab_request: {  }
    assert_redirected_to cab_request_path(assigns(:cab_request))
  end

  test "should destroy cab_request" do
    assert_difference('CabRequest.count', -1) do
      delete :destroy, id: @cab_request
    end

    assert_redirected_to cab_requests_path
  end
end
