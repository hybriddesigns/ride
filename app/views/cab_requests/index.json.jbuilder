json.array!(@cab_requests) do |cab_request|
  json.extract! cab_request, :id
  json.url cab_request_url(cab_request, format: :json)
end
