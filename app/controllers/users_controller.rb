class UsersController < ApplicationController
  #skip_before_filter :check_group_access, :only => [:logo, :css, :favicon, :background]
  before_filter :login_required, :only => [:edit, :update, :follow]
  before_filter :set_active_tag
  before_filter :set_active_user

  tabs :default => @active_tag

  subtabs :index => [[:reputation, "reputation"],
                     [:newest, "created_at desc"],
                     [:oldest, "created_at asc"],
                     [:name, "login asc"]]

  def index
    @active_section = "Thinking is free"
    set_page_title(t("users.index.title"))
    options =  {:per_page => params[:per_page]||24,
               :order => current_order,
               :page => params[:page] || 1}
    options[:login] = /^#{Regexp.escape(params[:q])}/ if params[:q]

    if options[:order] == "reputation"
      options[:order] = "membership_list.#{current_group.id}.reputation desc"
    end

    @users = current_group.users(options)

    

    @user = User.find_by_login_or_id(params[:id])
    @first_thought = @user

    #@item = Item.find_by_slug_or_id(params[:id])


    respond_to do |format|
      format.html
      format.json {
        render :json => @users.to_json(:only => %w[name login membership_list bio website location language])
      }
      format.js {
        html = render_to_string(:partial => "user", :collection  => @users)
        pagination = render_to_string(:partial => "shared/pagination", :object => @users,
                                      :format => "html")
        render :json => {:html => html, :pagination => pagination }
      }
    end

  end

  # render new.rhtml
  def new
    @user = User.new
    @user.timezone = AppConfig.default_timezone
  end

  def create
    @user = User.new
    @user.safe_update(%w[login email first_name last_name display_name password_confirmation password terms preferred_languages website language timezone identity_url bio hide_country], params[:user])


    first_name = params[:user][:first_name]
    last_name = params[:user][:last_name]
    display_slug = first_name.downcase + "-" + last_name.downcase
    display_name = first_name.capitalize + " " + last_name.capitalize
    @user.display_slug = display_slug
    @user.display_name = display_name

    email = params[:user][:email]
    @user.login = email

    @user.profile_images << ProfileImage.new
    @user.profile_images << ProfileImage.new

    @user.avatars << Avatar.new

    if params[:user]["birthday(1i)"]
      @user.birthday = build_date(params[:user], "birthday")
    end
    success = @user && @user.save
    if success && @user.errors.empty?
      # Protects against session fixation attacks, causes request forgery
      # protection if visitor resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset session
      sweep_new_users(current_group)
      @user.localize(request.remote_ip)
      flash[:notice] = t("flash_notice", :scope => "users.create")
      sign_in_and_redirect(:user, @user) # !! now logged in
    else
      flash[:error]  = t("flash_error", :scope => "users.create")
      render :action => 'new'
    end
  end

  def show
    @user = User.find_by_slug_or_id(params[:id])



    raise PageNotFound unless @user

    set_page_title("#{@user.display_name}")

    @q_sort, order = active_subtab(:sort)
    @items = @user.items.paginate(:page=>params[:items_page],
                                          :order => order,
                                          :per_page => 10,
                                          :group_id => current_group.id,
                                          :banned => false)

  


    @a_sort, order = active_subtab(:sort)
    @answers = @user.answers.paginate(:page=>params[:answers_page],
                                      :order => order,
                                      :group_id => current_group.id,
                                      :per_page => 10,
                                      :banned => false)

    @badges = @user.badges.paginate(:page => params[:badges_page],
                                    :group_id => current_group.id,
                                    :per_page => 25)

    @f_sort, order = active_subtab(:sort)
    @favorites = @user.favorites.paginate(:page => params[:favorites_page],
                                          :per_page => 25,
                                          :order => order,
                                          :group_id => current_group.id)

    @favorite_items = Item.find(@favorites.map{|f| f.item_id })

    add_feeds_url(url_for(:format => "atom"), t("feeds.user"))

    @user.viewed_on!(current_group) if @user != current_user && !is_bot?

    respond_to do |format|
      format.html
      format.atom
      format.json {
        render :json => @user.to_json(:only => %w[name membership_list bio website location language])
      }
    end
  end

  def edit
    @user = current_user
    @user.timezone = AppConfig.default_timezone if @user.timezone.blank?
  end

  def set_default_avatar
    @user = current_user
    @avatar = Avatar.find(params[:id])

    #@user.safe_update(%w[default_avatar], @avatar.id)
    @user.default_avatar = @avatar

    redirect_to avatars_path 

  end

  def update
    if params[:id] == 'login' && params[:user].nil? # HACK for facebook-connectable
      redirect_to current_user
      return
    end

    @user = current_user

    if params[:current_password] && @user.valid_password?(params[:current_password])
      @user.encrypted_password = ""
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
    end

    @user.safe_update(%w[slug login email display_name first_name last_name default_avatar language timezone preferred_languages 
                         notification_opts bio hide_country website website_url twitter twitter_url linkedin linkedin_url], params[:user])



    if params[:user]["birthday(1i)"]
      @user.birthday = build_date(params[:user], "birthday")
    end

    Magent.push("actors.judge", :on_update_user, @user.id, current_group.id)

    preferred_tags = params[:user][:preferred_tags]
    if @user.valid? && @user.save
      @user.add_preferred_tags(preferred_tags, current_group) if preferred_tags
      redirect_to user_path(@user)
    else
      render :action => "edit"
    end
  end

  def change_preferred_tags
    @user = current_user
    if params[:tags]
      if params[:opt] == "add"
        @user.add_preferred_tags(params[:tags], current_group) if params[:tags]
      elsif params[:opt] == "remove"
        @user.remove_preferred_tags(params[:tags], current_group)
      end
    end

    respond_to do |format|
      format.html {redirect_to items_path}
    end
  end

  def follow
    @user = User.find_by_login_or_id(params[:id])
    current_user.add_friend(@user)

    flash[:notice] = t("flash_notice", :scope => "users.follow", :user => @user.display_name)

    if @user.notification_opts.activities
      Notifier.deliver_follow(current_user, @user)
    end

    Magent.push("actors.judge", :on_follow, current_user.id, @user.id, current_group.id)

    respond_to do |format|
      format.html do
        redirect_to user_path(@user)
      end
      format.js {
        render(:json => {:success => true,
                 :message => flash[:notice] }.to_json)
      }
    end
  end

  def unfollow
    @user = User.find_by_login_or_id(params[:id])
    current_user.remove_friend(@user)

    flash[:notice] = t("flash_notice", :scope => "users.unfollow", :user => @user.login)

    Magent.push("actors.judge", :on_unfollow, current_user.id, @user.id, current_group.id)

    respond_to do |format|
      format.html do
        redirect_to user_path(@user)
      end
      format.js {
        render(:json => {:success => true,
                 :message => flash[:notice] }.to_json)
      }
    end
  end

  def autocomplete_for_user_login
    @users = User.all( :limit => params[:limit] || 20,
                       :fields=> 'login',
                       :login =>  /^#{Regexp.escape(params[:prefix].to_s.downcase)}.*/,
                       :order => "login desc")
    respond_to do |format|
      format.json {render :json=>@users}
    end
  end

  def destroy
    if false && current_user.delete # FIXME We need a better way to delete users
      flash[:notice] = t("destroyed", :scope => "devise.registrations")
    else
      flash[:notice] = t("destroy_failed", :scope => "devise.registrations")
    end
    return redirect_to(:root)
  end

  protected

  def set_active_tag
    @active_tag = "Login"
    @active_tag
  end

  def set_active_user
    @user = User.find_by_login_or_id(params[:id])
    if !@user
      @active_user = "Members"
    else
      @active_user = @user.login
    end
    @active_user
  end

  def active_subtab(param)
    key = params.fetch(param, "votes")
    order = "votes_average desc, created_at desc"
    case key
      when "votes"
        order = "votes_average desc, created_at desc"
      when "views"
        order = "views desc, created_at desc"
      when "newest"
        order = "created_at desc"
      when "oldest"
        order = "created_at asc"
    end
    [key, order]
  end
end


