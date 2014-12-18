Rails.application.routes.draw do
  devise_for :users
  resources :locations

  root 'cab_requests#new'
  get  'cab_requests/receive_sms' => 'cab_requests#receive_sms'
  # get  'cab_requests/receive_sms_for_ride' => 'cab_requests#receive_sms_for_ride'
  # get  'cab_requests/receive_sms_for_driver_registration' => 'cab_requests#receive_sms_for_driver_registration'
  resources :cab_requests
end
