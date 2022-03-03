TestFlight::Engine.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :devices, only: [:create, :destroy]
    end
  end
end