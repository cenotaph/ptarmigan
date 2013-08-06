# -*- encoding : utf-8 -*-
Ptarmigan::Application.routes.draw do
  mount Ckeditor::Engine => '/ckeditor'
  mount WillFilter::Engine => "/will_filter"  
  devise_for :users, :controllers => {:registrations => 'registrations'}

  themes_for_rails
  resources :attendees do
    # resources :event, :only => [:index]
    collection do
      post :check
    end

  end

  match '/feed', :to => "feed#index"
  match '/archive', :to => "events#archive"
  match '/about', :controller => "pages", :action => "show", :id => "about"
  match '/press', :controller => "pages", :action => "press", :id => "press"
  match "ckeditor/pictures", :via => :post, :controller => 'ckeditor/pictures', :action => :create
  match '/search/simple', :controller => 'application', :action => 'search'
  resources :airforms, :member => {:submit => :get}, :collection => {:submitted => :get}

  # logout '/air/logout', :controller => 'sessions', :action => 'destroy'
  # login '/air/login', :controller => 'sessions', :action => 'new_applicant'
  # register '/air/register', :controller => 'applicants', :action => 'create'
  # signup '/air/signup', :controller => 'applicants', :action => 'new'
  # activate '/air/activate/:activation_code', :controller => 'applicants', :action => 'activate', :activation_code => nil
  resources :applicants
  resources :places
  
  resources :proposals do
    collection do
      get :thank_you
      get :axis_of_praxis
    end
  end
  
  match '/air', :controller => 'pages', :action => 'air'
  # connect '/en/pages/air', :controller => 'pages', :action => 'air'
  # connect '/fi/pages/air', :controller => 'pages', :action => 'air'




  match '/staff', :controller => 'admin/reports', :action => :index
  resources :calendar do
    collection do
      get :update_calendar
    end
  end
  #register '/register', :controller => 'users', :action => 'create'
  #signup '/signup', :controller => 'users', :action => 'new'
  resources :users
  match '/pages/frontpage', {:controller => :pages, :action => :frontpage}
  match '/pages/:id', {:controller => :pages, :action => :show, :id => :id }
  # resource :session, :member => {:new_applicant => :get, :applicant_create => :put}
  resources :events do
    resources :attendees
    collection do
      get :archive
      get :archives
    end
  end
  resources :projects do
    collection do
      get :archive
    end
  end
  resources :artists do
    collection do
      get :archive
    end
  end
  resources :pages do
    collection do
      get :frontpage
    end
  end
  resources :posts do
    collection do
      get :witnessed
    end
  end
    
  resources :institutions
  
  match '/admin/wiki',  :controller => 'admin/wikipages',  :action => 'show', :title => 'Home page'
  match '/admin/wiki/:title', :controller => 'admin/wikipages',  :action => 'show', :title => :title

  match '/admin/wikipages.:format', :controller => 'admin/wikipages', :action => 'index'
  match '/admin/wikirevisions.:format', :controller => 'admin/wikirevisions', :action => 'index'

  match '/admin/wiki/:title', :controller => 'admin/wikipages', :action => 'show'
  # connect ':title.:format', :controller => 'admin/wikipages', :action => 'show'

  match '/admin/wiki/:title/history', :controller => 'admin/wikipages', :action => 'history', :as => :admin_wikipage_history
  match '/admin/:title/history.:format', :controller => 'admin/wikipages', :action => 'history'
  
  match '/admin/wiki/:title/edit', :controller => 'admin/wikipages', :action => 'edit'

  namespace :admin do
    resources :events
    resources :wikirevisions
    resources :wikipages
    resources :documents
    resources :expenses
    resources :subsites
    resources :projects
    resources :pages
    resources :users
    resources :reports do
      collection do
        post :search
      end
    end
    resources :incomes
    resources :artists
    resources :videohosts
    resources :videos
    resources :flickers do
      member do
        get :remove_carousel
        get :set_carousel
      end
    end
    resources :places
    resources :presslinks
    resources :posts
    resources :airforms
    resources :budgetareas
    resources :wikifiles
    resources :chatters do
      resources :comments
    end

    resources :proposals do
      resources :proposalcomments
    end
    resources :proposalcomments
    resources :resources
    resources :attendees
  end
  match   '/add_to_list', :controller => :application, :action => :add_to_mailchimp
  root :controller => 'pages', :action => 'frontpage'
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with root -- just remember to delete public/index.html.
  # root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  match '/:controller/:action/:id'
  match '/:controller/:action/:id.:format'
  
end
