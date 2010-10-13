ActionController::Routing::Routes.draw do |map|
  map.oauth_authorize '/oauth/start', :controller => 'oauth', :action => 'start'
  map.oauth_callback '/oauth/callback', :controller => 'oauth', :action => 'callback'

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

  map.resources :users, :member => { :change_preferred_tags => :any,
                                     :follow => :any, :unfollow => :any},
                        :collection => {:autocomplete_for_user_login => :get},
                        :as => "members"
  map.resources :session
  map.resources :ads
  map.resources :adsenses
  map.resources :adbards
  map.resources :badges
  map.resources :pages, :member => {:css => :get, :js => :get}
  map.resources :announcements, :collection => {:hide => :any }
  map.resources :imports, :collection => {:send_confirmation => :post}

  #map.resources :links
  #map.resources :links, :controller => :links, :as => "bookmarks"
  #map.bookmarks 'bookmarks/signup', :controller => :bookmarks, :action => :signup #:requirements => {:tags => /\S+/}
  #map.bookmarks 'bookmarks/new', :controller => :bookmarks, :action => :new #:requirements => {:tags => /\S+/}
  #map.bookmarks 'bookmarks/:tags', :controller => :bookmarks, :action => :index,:requirements => {:tags => /\S+/}
  #map.bookmarks 'bookmarks', :controller => :bookmarks

  #map.channels :channels
  map.channels 'channels/:tags', :controller => :channels, :action => :index,:requirements => {:tags => /\S+/}

  #map.resources :channels, :collection => {:tags => :get}
  #map.connect 'channels/explore/:tags', :controller => :channels, :action => :index,:requirements => {:tags => /\S+/}
              #:as => "channels"

  def build_create_routes(router, options ={})
    router.with_options(options) do |route|

      route.resources :create, :collection => {:tags => :get,
                                                  :tags_for_autocomplete => :get,
                                                  :unanswered => :get,
                                                  :related_items => :get,
                                                  :mode => :get},
                                :member => {:solve => :get,
                                            :unsolve => :get,
                                            :favorite => :any,
                                            :unfavorite => :any,
                                            :watch => :any,
                                            :unwatch => :any,
                                            :history => :get,
                                            :revert => :get,
                                            :diff => :get,
                                            :move => :get,
                                            :move_to => :put,
                                            :retag => :get,
                                            :retag_to => :put,
                                            :close => :put,
                                            :open => :put} do |create|
        create.resources :comments
        create.resources :answers, :member => {:history => :get,
                                                  :diff => :get,
                                                  :revert => :get} do |answers|
          answers.resources :comments
          answers.resources :flags
        end
        create.resources :flags
        create.resources :close_requests
        create.resources :open_requests
      end
    end
  end

  map.connect 'create/topic/:tags', :controller => :create, :action => :index,:requirements => {:tags => /\S+/}
  map.connect 'create/unanswered/tags/:tags', :controller => :create, :action => :unanswered

  build_create_routes(map)
  build_create_routes(map, :path_prefix => '/:language', :name_prefix => "with_language_") #deprecated route

  def build_items_routes(router, options ={})
    router.with_options(options) do |route|
      route.se_url "/item/:id/:slug", :controller => "items", :action => "show", :id => /\d+/,
 :conditions => { :method => :get }
      route.resources :items, :collection => {:tags => :get,
                                                  :tags_for_autocomplete => :get,
                                                  :unanswered => :get,
                                                  :related_items => :get},
                                :member => {:solve => :get,
                                            :unsolve => :get,
                                            :favorite => :any,
                                            :unfavorite => :any,
                                            :watch => :any,
                                            :unwatch => :any,
                                            :history => :get,
                                            :revert => :get,
                                            :diff => :get,
                                            :move => :get,
                                            :move_to => :put,
                                            :retag => :get,
                                            :retag_to => :put,
                                            :close => :put,
                                            :open => :put} do |items|
        items.resources :comments
        items.resources :answers, :member => {:history => :get,
                                                  :diff => :get,
                                                  :revert => :get} do |answers|
          answers.resources :comments
          answers.resources :flags
        end
        items.resources :flags
        items.resources :close_requests
        items.resources :open_requests
      end
    end
  end

  map.connect 'items/topic/:tags', :controller => :items, :action => :index,:requirements => {:tags => /\S+/}
  map.connect 'items/unanswered/tags/:tags', :controller => :items, :action => :unanswered

  build_items_routes(map)
  build_items_routes(map, :path_prefix => '/:language', :name_prefix => "with_language_") #deprecated route


  def build_questions_routes(router, options ={})
    router.with_options(options) do |route|
      route.se_url "/question/:id/:slug", :controller => "questions", :action => "show", :id => /\d+/,
 :conditions => { :method => :get }
      route.resources :questions, :collection => {:tags => :get,
                                                  :tags_for_autocomplete => :get,
                                                  :unanswered => :get,
                                                  :related_items => :get},
                                :member => {:solve => :get,
                                            :unsolve => :get,
                                            :favorite => :any,
                                            :unfavorite => :any,
                                            :watch => :any,
                                            :unwatch => :any,
                                            :history => :get,
                                            :revert => :get,
                                            :diff => :get,
                                            :move => :get,
                                            :move_to => :put,
                                            :retag => :get,
                                            :retag_to => :put,
                                            :close => :put,
                                            :open => :put} do |questions|
        questions.resources :comments
        questions.resources :answers, :member => {:history => :get,
                                                  :diff => :get,
                                                  :revert => :get} do |answers|
          answers.resources :comments
          answers.resources :flags
        end
        questions.resources :flags
        questions.resources :close_requests
        questions.resources :open_requests
      end
    end
  end

  map.connect 'questions/topic/:tags', :controller => :questions, :action => :index,:requirements => {:tags => /\S+/}
  map.connect 'questions/unanswered/tags/:tags', :controller => :questions, :action => :unanswered

  build_questions_routes(map)
  build_questions_routes(map, :path_prefix => '/:language', :name_prefix => "with_language_") #deprecated route
 

  def build_discussions_routes(router, options ={:mode => "discussions"})
    router.with_options(options) do |route|
      route.se_url "/discussion/:id/:slug", :controller => "discussions", :action => "show", :id => /\d+/,
 :conditions => { :method => :get }, :mode => "discussions"
      route.resources :discussions, :collection => {:tags => :get,
                                                  :tags_for_autocomplete => :get,
                                                  :unanswered => :get,
                                                  :related_items => :get,
                                                  :mode => :get},
                                :member => {:solve => :get,
                                            :unsolve => :get,
                                            :favorite => :any,
                                            :unfavorite => :any,
                                            :watch => :any,
                                            :unwatch => :any,
                                            :history => :get,
                                            :revert => :get,
                                            :diff => :get,
                                            :move => :get,
                                            :move_to => :put,
                                            :retag => :get,
                                            :retag_to => :put,
                                            :close => :put,
                                            :open => :put} do |discussions|
        discussions.resources :comments
        discussions.resources :answers, :member => {:history => :get,
                                                  :diff => :get,
                                                  :revert => :get} do |answers|
          answers.resources :comments
          answers.resources :flags
        end
        discussions.resources :flags
        discussions.resources :close_requests
        discussions.resources :open_requests
      end
    end
  end

  map.connect 'discussions/topic/:tags', :controller => :discussions, :action => :index,:requirements => {:tags => /\S+/}
  map.connect 'discussions/unanswered/tags/:tags', :controller => :discussions, :action => :unanswered

  build_discussions_routes(map, :mode=>"discussions")
  build_discussions_routes(map, :path_prefix => '/:language', :name_prefix => "with_language_") #deprecated route



  def build_newsfeeds_routes(router, options ={})
    router.with_options(options) do |route|
      route.se_url "/newsfeeds/:id/:slug", :controller => "news", :action => "show", :id => /\d+/,
 :conditions => { :method => :get }
      route.resources :newsfeeds, :collection => {:tags => :get,
                                                  :tags_for_autocomplete => :get,
                                                  :unanswered => :get,
                                                  :related_items => :get,
                                                  :mode => :get},
                                :member => {:solve => :get,
                                            :unsolve => :get,
                                            :favorite => :any,
                                            :unfavorite => :any,
                                            :watch => :any,
                                            :unwatch => :any,
                                            :history => :get,
                                            :revert => :get,
                                            :diff => :get,
                                            :move => :get,
                                            :move_to => :put,
                                            :retag => :get,
                                            :retag_to => :put,
                                            :close => :put,
                                            :open => :put} do |newsfeeds|
        newsfeeds.resources :comments
        newsfeeds.resources :answers, :member => {:history => :get,
                                                  :diff => :get,
                                                  :revert => :get} do |answers|
          answers.resources :comments
          answers.resources :flags
        end
        newsfeeds.resources :flags
        newsfeeds.resources :close_requests
        newsfeeds.resources :open_requests
      end
    end
  end

  map.connect 'newsfeeds/topic/:tags', :controller => :news, :action => :index,:requirements => {:tags => /\S+/}
  map.connect 'newsfeeds/unanswered/tags/:tags', :controller => :news, :action => :unanswered

  build_newsfeeds_routes(map)
  build_newsfeeds_routes(map, :path_prefix => '/:language', :name_prefix => "with_language_") #deprecated route


  def build_articles_routes(router, options ={})
    router.with_options(options) do |route|
      route.se_url "/articles/:id/:slug", :controller => "articles", :action => "show", :id => /\d+/,
 :conditions => { :method => :get }
      route.resources :articles, :collection => {:tags => :get,
                                                  :tags_for_autocomplete => :get,
                                                  :unanswered => :get,
                                                  :related_items => :get,
                                                  :mode => :get},
                                :member => {:solve => :get,
                                            :unsolve => :get,
                                            :favorite => :any,
                                            :unfavorite => :any,
                                            :watch => :any,
                                            :unwatch => :any,
                                            :history => :get,
                                            :revert => :get,
                                            :diff => :get,
                                            :move => :get,
                                            :move_to => :put,
                                            :retag => :get,
                                            :retag_to => :put,
                                            :close => :put,
                                            :open => :put} do |articles|
        articles.resources :comments
        articles.resources :answers, :member => {:history => :get,
                                                  :diff => :get,
                                                  :revert => :get} do |answers|
          answers.resources :comments
          answers.resources :flags
        end
        articles.resources :flags
        articles.resources :close_requests
        articles.resources :open_requests
      end
    end
  end

  map.connect 'articles/topic/:tags', :controller => :articles, :action => :index,:requirements => {:tags => /\S+/}
  map.connect 'articles/unanswered/tags/:tags', :controller => :articles, :action => :unanswered

  build_articles_routes(map)
  build_articles_routes(map, :path_prefix => '/:language', :name_prefix => "with_language_") #deprecated route

  def build_blogs_routes(router, options ={})
    router.with_options(options) do |route|
      route.se_url "/blogs/:id/:slug", :controller => "blogs", :action => "show", :id => /\d+/,
 :conditions => { :method => :get }
      route.resources :blogs, :collection => {:tags => :get,
                                                  :tags_for_autocomplete => :get,
                                                  :unanswered => :get,
                                                  :related_items => :get,
                                                  :mode => :get},
                                :member => {:solve => :get,
                                            :unsolve => :get,
                                            :favorite => :any,
                                            :unfavorite => :any,
                                            :watch => :any,
                                            :unwatch => :any,
                                            :history => :get,
                                            :revert => :get,
                                            :diff => :get,
                                            :move => :get,
                                            :move_to => :put,
                                            :retag => :get,
                                            :retag_to => :put,
                                            :close => :put,
                                            :open => :put} do |blogs|
        blogs.resources :comments
        blogs.resources :answers, :member => {:history => :get,
                                                  :diff => :get,
                                                  :revert => :get} do |answers|
          answers.resources :comments
          answers.resources :flags
        end
        blogs.resources :flags
        blogs.resources :close_requests
        blogs.resources :open_requests
      end
    end
  end

  map.connect 'blogs/topic/:tags', :controller => :blogs, :action => :index,:requirements => {:tags => /\S+/}
  map.connect 'blogs/unanswered/tags/:tags', :controller => :blogs, :action => :unanswered

  build_blogs_routes(map)
  build_blogs_routes(map, :path_prefix => '/:language', :name_prefix => "with_language_") #deprecated route

  def build_videos_routes(router, options ={})
    router.with_options(options) do |route|
      route.se_url "/videos/:id/:slug", :controller => "videos", :action => "show", :id => /\d+/,
 :conditions => { :method => :get }
      route.resources :videos, :collection => {:tags => :get,
                                                  :tags_for_autocomplete => :get,
                                                  :unanswered => :get,
                                                  :related_items => :get,
                                                  :mode => :get},
                                :member => {:solve => :get,
                                            :unsolve => :get,
                                            :favorite => :any,
                                            :unfavorite => :any,
                                            :watch => :any,
                                            :unwatch => :any,
                                            :history => :get,
                                            :revert => :get,
                                            :diff => :get,
                                            :move => :get,
                                            :move_to => :put,
                                            :retag => :get,
                                            :retag_to => :put,
                                            :close => :put,
                                            :open => :put} do |videos|
        videos.resources :comments
        videos.resources :answers, :member => {:history => :get,
                                                  :diff => :get,
                                                  :revert => :get} do |answers|
          answers.resources :comments
          answers.resources :flags
        end
        videos.resources :flags
        videos.resources :close_requests
        videos.resources :open_requests
      end
    end
  end

  map.connect 'videos/topic/:tags', :controller => :videos, :action => :index,:requirements => {:tags => /\S+/}
  map.connect 'videos/unanswered/tags/:tags', :controller => :videos, :action => :unanswered
  #map.connect 'videos/new', :controller => :videos, :action => :new, :as => "new"

  build_videos_routes(map)
  build_videos_routes(map, :path_prefix => '/:language', :name_prefix => "with_language_") #deprecated route

  def build_bookmarks_routes(router, options ={})
    router.with_options(options) do |route|
      route.se_url "/videos/:id/:slug", :controller => "bookmarks", :action => "show", :id => /\d+/,
 :conditions => { :method => :get }
      route.resources :bookmarks, :collection => {:tags => :get,
                                                  :tags_for_autocomplete => :get,
                                                  :unanswered => :get,
                                                  :related_items => :get,
                                                  },
                                :member => {:solve => :get,
                                            :unsolve => :get,
                                            :favorite => :any,
                                            :unfavorite => :any,
                                            :watch => :any,
                                            :unwatch => :any,
                                            :history => :get,
                                            :revert => :get,
                                            :diff => :get,
                                            :move => :get,
                                            :move_to => :put,
                                            :retag => :get,
                                            :retag_to => :put,
                                            :close => :put,
                                            :open => :put} do |bookmarks|
        bookmarks.resources :comments
        bookmarks.resources :answers, :member => {:history => :get,
                                                  :diff => :get,
                                                  :revert => :get} do |answers|
          answers.resources :comments
          answers.resources :flags
        end
        bookmarks.resources :flags
        bookmarks.resources :close_requests
        bookmarks.resources :open_requests
      end
    end
  end

  map.connect 'bookmarks/topic/:tags', :controller => :bookmarks, :action => :index,:requirements => {:tags => /\S+/}
  map.connect 'bookmarks/unanswered/tags/:tags', :controller => :bookmarks, :action => :unanswered

  build_bookmarks_routes(map)
  build_bookmarks_routes(map, :path_prefix => '/:language', :name_prefix => "with_language_") #deprecated route


  #map.questions 'questions/:action/:id', :controller => 'items', :mode => 'question'
  #map.questions 'questions/topics/:tags', :controller => 'items', :action => :index,:requirements => {:tags => /\S+/}

  #map.discussions 'discussions/:action/:id', :controller => 'items', :mode => 'discussion'


  map.resources :groups, :member => {:accept => :get,
                                     :close => :get,
                                     :allow_custom_ads => :get,
                                     :disallow_custom_ads => :get,
                                     :logo => :get,
                                     :favicon => :get,
                                     :css => :get},
                          :collection => { :autocomplete_for_group_slug => :get}

  map.resources :votes

  map.resources :widgets, :member => {:move => :post}, :path_prefix => "/manage"
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
  end

  map.search '/search.:format', :controller => "searches", :action => "index"
  map.about '/about', :controller => "groups", :action => "show"
  map.root :controller => "welcome"

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
