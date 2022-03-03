Rails.application.routes.draw do
  mount TestFlight::Engine => "/test_flight"
end
