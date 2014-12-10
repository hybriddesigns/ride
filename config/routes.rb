Rails.application.routes.draw do
  root 'cab_requests#new'
  get  'cab_requests/new/:user_cell_no/:location' => 'cab_requests#new'
  get  'cab_requests/receive_sms_for_ride' => 'cab_requests#receive_sms_for_ride'
  get  'cab_requests/receive_sms_for_driver_registration' => 'cab_requests#receive_sms_for_driver_registration'
  resources :cab_requests
end
