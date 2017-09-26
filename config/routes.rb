Spree::Core::Engine.add_routes do
  # Add your extension routes here
  namespace :admin do
    resources :reports, only: [:index, :show] do
      collection do
        get :sales_total
        post :sales_total
        get :out_of_stock
        post :out_of_stock
      end
    end
  end  
end
