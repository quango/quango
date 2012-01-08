ActionController::Routing::Routes.draw do |map|
  map.resources :dummies
  #map.resources :images

  map.oauth_authorize '/oauth/start', :controller => 'oauth', :action => 'start'
  map.oauth_callback '/oauth/callback', :controller => 'oauth', :action => 'callback'

  map.google_authorize '/google/start', :controller => 'oauth', :action => 'start'
  map.google_callback '/google/callback', :controller => 'oauth', :action => 'callback'
  map.google_share '/google/share', :controller => 'oauth', :action => 'share'

  map.facebook_authorize '/facebook/start', :controller => 'oauth', :action => 'start'
  map.facebook_callback '/facebook/callback', :controller => 'oauth', :action => 'callback'
  map.facebook_share '/facebook/share', :controller => 'oauth', :action => 'share'

  map.twitter_authorize '/twitter/start', :controller => 'twitter', :action => 'start'
  map.twitter_callback '/twitter/callback', :controller => 'twitter', :action => 'callback'
  map.twitter_share '/twitter/share', :controller => 'twitter', :action => 'share'

  map.devise_for :users, :path_names => { :sign_in => 'login', :sign_out => 'logout' }
  map.confirm_age_welcome 'confirm_age_welcome', :controller => 'welcome', :action => 'confirm_age'
  map.change_language_filter '/change_language_filter', :controller => 'welcome', :action => 'change_language_filter'
  map.register '/register', :controller => 'users', :action => 'create'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.moderate '/moderate', :controller => 'admin/moderate', :action => 'index'
  map.ban '/moderate/ban', :controller => 'admin/moderate', :action => 'ban'
  map.unban '/moderate/unban', :controller => 'admin/moderate', :action => 'unban'
  map.facts '/facts', :controller => 'welcome', :action => 'facts'
  map.plans '/plans', :controller => 'doc', :action => 'plans'
  map.chat '/chat', :controller => 'doc', :action => 'chat'
  map.feedback '/feedback', :controller => 'welcome', :action => 'feedback'
  map.send_feedback '/send_feedback', :controller => 'welcome', :action => 'send_feedback'
  map.settings '/settings', :controller => 'users', :action => 'edit'
  map.tos '/tos', :controller => 'doc', :action => 'tos'
  map.privacy '/privacy', :controller => 'doc', :action => 'privacy'


  map.resources :avatars, :member => { :crop => :get, :pull => :get, :set_default => :get,  :set_profile => :get }, :as => "profile-images"


  map.resources :users, :member => { :change_preferred_tags => :any,
                                     :follow => :any, :unfollow => :any},
                        :collection => {:autocomplete_for_user_login => :get},
                        :as => "members"


  map.resources :session
  map.resources :ads
  map.resources :adsenses
  map.resources :adbards
  map.resources :badges
  #system pages
  map.resources :pages, :member => {:css => :get, :js => :get}, :as => "about"
  map.resources :announcements, :collection => {:hide => :any }
  map.resources :imports, :collection => {:send_confirmation => :post}

  map.channels 'channels/:tags', :controller => :channels, :action => :index,:requirements => {:tags => /\S+/}

  map.resources :create, :action => :new, :as => "add"
  map.root :controller => "welcome"

  #if current_group.group_type == "mobile"
   # doctypes_rewrite = "mo"
  #else
   # doctypes_rewrite = "member"
  #end

  def build_items_routes(router, options ={})
    router.with_options(options) do |route|
      route.se_url "/:doctype/:id/:slug", :controller => "items", :action => "show", :section => /\d+/, :id => /\d+/, :conditions => { :method => :get }
      route.resources :doctypes, :as => "m" do |doctypes|

        doctypes.resources :items, 
                           :collection => {:get_video_info => :get, :tags => :get,:tags_for_autocomplete => :get,:unanswered => :get,:related_items => :get},
                           :member     => {:bump => :any,:solve => :get,:unsolve => :get,:favorite => :any,:unfavorite => :any,:watch => :any,:unwatch => :any,
                                                 :history => :get,:revert => :get,:diff => :get, :change_doctype => :get,
                                                 :move => :get,:move_to => :put, :retag => :get,:retag_to => :put,
                                            :close => :put,:open => :put,:meta => :get,:distribute => :get,:describe => :get,:tag => :get, :advanced => :get, :link => :any}, :name_prefix => nil, :as => 'id'  do |items| #:name_prefix => nil,

        items.resources :comments


        items.resources :images, :member => { :crop => :get, 
                                              :pull => :get, 
                                              :set_default_thumbnail => :get, 
                                              :flip => :get, :flop => :get,
                                              :rotate_left => :get, :rotate_right => :get, :rotate_180 => :get,
                                              :move => :post
                                              }
        items.resources :answers, :member => {:history => :get,
                                                  :diff => :get,
                                                  :revert => :get} do |answers|
          answers.resources :comments
          answers.resources :flags
        end

        items.resources :flags
        items.resources :close_requests
        items.resources :open_requests
        items.resources :videos #this item has_many videos
        items.resources :bunnies #this item has_many bunnies
        

        end



      end

    end
  end

  map.connect 'items/topic/:tags', :controller => :items, :action => :index,:requirements => {:tags => /\S+/}
  map.connect 'items/unanswered/tags/:tags', :controller => :items, :action => :unanswered



  #map.connect 'doctypes', :controller => :items, :action => :show, :as => ''

  build_items_routes(map) #, :as => ':doctype_id/:item_id', :only => ':show, :index')



  map.resources :doctypes, :member => {:move => :post, :list => :get}



  



  map.resources :groups, :member => {:accept => :get,
                                     :close => :get,
                                     :allow_custom_ads => :get,
                                     :disallow_custom_ads => :get,
                                     :image_of_the_day => :get,
                                     :logo => :get,
                                     :sponsor_logo => :get,
                                     :sponsor_logo_wide => :get,
                                     :sponsor_logo_narrow => :get,
                                     :signup_button_css => :get,
                                     :check => :any,
                                     :favicon => :get,
                                     :background => :get,
                                     :group_style => :get,
                                     :group_style_mobile => :get,
                                     :css => :get},
                          :collection => { :autocomplete_for_group_slug => :get}, :as => "groups"

  #map.groups '/check',:controller => "groups", :action => "post", :as => "communities"


  map.resources :votes


  map.resources :widgets, :member => { :move => :post}, :path_prefix => "/manage"
  map.resources :sponsored_links, :member => {:image => :get,:move => :post}, :path_prefix => "/manage"

  map.resources :transactions
  map.resources :subscriptions
  map.resources :headers, :member => {:crop => :get,
                                              :pull => :get, 
                                              :set_default_header => :get, 
                                              :flip => :get, :flop => :get,
                                              :desat => :get, :negate => :get, :watermark => :get,
                                              :rotate_left => :get, :rotate_right => :get, :rotate_180 => :get,
                                              :move => :post}

  map.resources :members, :path_prefix => "/manage"

  map.with_options :controller => 'admin/manage', :name_prefix => "manage_",
                   :path_prefix => "/manage" do |manage|
    manage.properties '/properties', :action => 'properties'
    manage.content '/content', :action => 'content'
    manage.theme '/theme', :action => 'theme'

    manage.actions '/actions', :action => 'actions'
    manage.stats '/stats', :action => 'stats'
    manage.reputation '/reputation', :action => 'reputation'
    manage.domain '/domain', :action => 'domain'
    manage.welcome '/welcome', :action => 'welcome'
  end

  #map.resources :nodes , :controller => :items, :action => :index, :member => {:section => :any}, :as => ":section"

  map.search '/search.:format', :controller => "searches", :action => "index"
  map.about '/about', :controller => "groups", :action => "show"




  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
