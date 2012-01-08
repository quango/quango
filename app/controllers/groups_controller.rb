class GroupsController < ApplicationController
  skip_before_filter :check_group_access, :only => [:logo, :css, :favicon, :background]
  before_filter :login_required, :except => [:pages, :index, :show, :logo,:sponsor_logo_wide,:sponsor_logo_narrow,:group_style,:group_style_mobile, :css, :signup_button_css, :favicon, :background]
  before_filter :check_permissions, :only => [:edit, :update, :close]
  before_filter :moderator_required , :only => [:accept, :destroy]
  subtabs :index => [ [:most_active, "activity_rate desc"], [:newest, "created_at desc"],
                      [:oldest, "created_at asc"], [:name, "name asc"]]
  # GET /groups
  # GET /groups.json
  def index
    @state = "active"
    case params.fetch(:tab, "active")
      when "pendings"
        @state = "pending"
    end
    @active_section = "communities"

    options = {:per_page => params[:per_page] || 15,
               :page => params[:page],
               :state => @state,
               :order => current_order,
               :private => false
              }

    if params[:q].blank?
      @groups = Group.paginate(options)
    else
      @groups = Group.filter(params[:q], options)
    end

    respond_to do |format|
      format.html # index.html.haml
      format.json  { render :json => @groups }
      format.js do
        html = render_to_string(:partial => "group", :collection  => @groups)
        pagination = render_to_string(:partial => "shared/pagination", :object => @groups,
                                      :format => "html")
        render :json => {:html => html, :pagination => pagination }
      end
    end
  end

  # GET /groups/1
  # GET /groups/1.json
  def show
    @active_subtab = "about"

    if params[:id]
      @group = Group.find_by_slug_or_id(params[:id])
    else
      @group = current_group
    end
    raise PageNotFound if @group.nil?

    @comments = @group.comments.paginate(:page => params[:page].to_i,
                                         :per_page => params[:per_page] || 10 )

    @comment = Comment.new


    respond_to do |format|
      format.html # show.html.erb
      format.json  { render :json => @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.json
  def new

    @active_subtab = "New"

    @group = Group.new
    #@group.parent_id = current_group.id

    respond_to do |format|
      format.html # new.html.erb
      format.json  { render :json => @group }
    end
  end

  def check

    @active_subtab = "Check"

    respond_to do |format|
      format.html 
      format.json  { render :json => @group }
    end
  end


  # GET /groups/1/edit
  def edit
  end



  # POST /groups
  # POST /groups.json
  def create
    @group = Group.new
    @group.safe_update(%w[name group_type agent_id owner_id parent_id name_highlight legend description default_tags subdomain logo logo_path favicon_path forum
                          custom_favicon language theme custom_css wysiwyg_editor], params[:group])

    @group.safe_update(%w[isolate domain private], params[:group]) if current_user.admin?

    cu = current_user

    @group.agent_id = cu
    @group.parent_id = current_group.id
    @group.owner_id = cu

    @group.state = "active"


    slug = @group.name
    @group.subdomain = @group.name

    #@group.subdomain = slug

    #@group.widgets << TopUsersWidget.new
    #@group.widgets << UsersWidget.new

    #Create initial doctype

    doctypes = Array.new
    doctypes << Doctype.new(:name => "q", :doctype => "standard", :create_label => "Ask a question", :created_label => "asked a question", :group_id => @group.id)
    #doctypes << Doctype.new(:name => "something ...

    doctypes.each do |doctype| 
     doctype.hidden = true
     doctype.save!
    end

    doctypes.each do |doctype| 
     doctype.hidden = false
     #@group.quick_create = doctype
     doctype.save!
    end

    @group.has_quick_create = true
    @group.quick_create = doctypes.first.id

    #Create standard pages

    pages = Array.new

    Dir.glob(RAILS_ROOT+"/db/fixtures/pages/*.markdown") do |page_path|
      basename = File.basename(page_path, ".markdown")
      title = basename.gsub(/\.(\w\w)/, "").titleize
      language = $1
      body = File.read(page_path)

      pages << Page.create(:title => title, :language => language, :body => body, :user_id => current_group.owner, :group_id => @group.id)
      
    end

    pages.each do |page| 
     page.save!
    end

    #Create the default question set
    #TODO: Create default question sets based on the type of group being created - eg. Business, Personal etc

    Dir.glob(RAILS_ROOT+"/db/fixtures/questions/*.yml") do |page_path|

      doctype_id = @group.quick_create
      question = Item.new
      language = "en"
      item_contents = YAML.load_file(page_path)
      title = item_contents["title"]
      body = item_contents["body"]      

      question = Item.create(:doctype_id => doctype_id,:title => title, :language => language, :body => body, :user_id => current_user, :group_id => @group.id)
      question.save!


    end

 
    ##Create the initial subscription
    subscriptions = Array.new

    #@user = current_user
    #@group = current_group

    @subscription = Subscription.new
    @subscription.name = @group.name + "subscription"
    @subscription.group = @group
    @subscription.user = @user
    @subscription.starts_at = Time.now
    @subscription.ends_at = Time.now + 2.minutes
    @subscription.save!

    subscriptions.each do |subscription|
      #subscription = Subscription.new
      subscription.save!
    end



    respond_to do |format|
      if @group.save
        @group.add_member(current_user, "owner")
        @group.add_member(current_user, "agent")
        flash[:notice] = I18n.t("groups.create.flash_notice")

        if @group.group_type == "mobile"
          #format.html { redirect_to(domain_url(:custom => @group.domain, :controller => "admin/manage", :action => "properties") << "?tab=colour_wheel") }
          format.html { redirect_to(domain_url(:custom => @group.domain))}
          format.json  { render :json => @group.to_json, :status => :created, :location => @group }
        else
          format.html { redirect_to(domain_url(:custom => @group.domain, :controller => "admin/manage", :action => "properties")) }
          format.json  { render :json => @group.to_json, :status => :created, :location => @group }
        end

      else
        format.html { render :action => "new" }
        format.json { render :json => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.json
  def update
    @group.safe_update(%w[group_type name name_highlight name_link name_highlight_link disable_signups
                          other_groups_facebook other_groups_linkedin other_groups_twitter other_groups_google
                          group_address_i group_address_ii group_city group_state group_region group_postcode group_phone group_fax
                          display_name_i display_name_i_link display_name_ii display_name_ii_link
                          has_strapline strapline legend has_welcome_features has_product_gallery has_video_on_homepage above_the_fold below_the_fold
                          description has_custom_channels custom_channels custom_channel_content default_tags subdomain 
                          has_quick_create quick_create quick_create_label quick_create_heading
                          has_leaderboard leaderboard_content has_custom_leaderboard custom_leaderboard_content 
                          has_medium_rectangle medium_rectangle_content group_categories show_category_navigation show_context_navigation
                          has_threeone_rectangle threeone_rectangle_content has_bumper bumper_content welcome_layout has_slideshow slideshow_content
                          logo logo_info logo_only text_only
                          has_custom_toolbar custom_toolbar_link custom_toolbar_image custom_toolbar_image_info
                          forum notification_from notification_email
                          custom_favicon language theme reputation_rewards reputation_constrains share_box
                          hidden has_adult_content registered_only openid_only custom_css wysiwyg_editor fb_button share show_beta_tools
                          publish_label signup_heading leaders_label about_label has_landing landing_labels has_landing_bg landing_bg
                          primary primary_dark secondary tertiary supplementary supplementary_dark supplementary_lite header_bg_image background toolbar_bg toolbar_bg_image header_bg
                          robots logo_path favicon_path link_colour text_colour sponsor_logo_wide_info sponsor_logo_narrow_info
                          has_sponsor has_sponsors sponsor_label sponsors_label sponsor_name sponsor_link sponsor_logo_wide sponsor_logo_narrow show_sponsor_description show_sponsor_description_boxheader sponsor_description sponsor_description_boxheader
                          show_signup_button signup_button_title signup_button_description signup_button_label signup_button_footnote signup_custom_css
                         ], params[:group])

    @group.safe_update(%w[isolate show_group_create domain private has_custom_analytics has_custom_html has_custom_js], params[:group]) #if current_user.admin?
    @group.safe_update(%w[analytics_id analytics_vendor], params[:group]) if @group.has_custom_analytics
    @group.custom_html.update_attributes(params[:group][:custom_html] || {}) if @group.has_custom_html

    respond_to do |format|
      if @group.save
        if @group.group_type != "mobile"
          flash[:notice] = 'Group was successfully updated.' # TODO: i18n
          format.html { redirect_to(params[:source] ? params[:source] : group_path(@group)) }
          format.json  { head :ok }
        end
        format.html { redirect_to(params[:source] ? params[:source] : group_path(@group)) }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.json  { render :json => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
    @group = Group.find_by_slug_or_id(params[:id])
    @group.destroy

    respond_to do |format|
      format.html { redirect_to(groups_url) }
      format.json  { head :ok }
    end
  end

  def accept
    @group = Group.find_by_slug_or_id(params[:id])
    @group.has_custom_ads = true if params["has_custom_ads"] == "true"
    @group.state = "active"
    @group.save
    redirect_to group_path(@group)
  end

  def close
    @group.state = "closed"
    @group.save
    redirect_to group_path(@group)
  end

  def logo
    @group = Group.find_by_slug_or_id(params[:id], :select => [:file_list])
    if @group && @group.has_logo?
      send_data(@group.logo.try(:read), :filename => "logo.#{@group.logo.extension}", :type => @group.logo.content_type,  :disposition => 'inline')
    else
      render :text => ""
    end
  end

  def sponsor_logo
    @group = Group.find_by_slug_or_id(params[:id], :select => [:file_list])
    if @group && @group.has_logo?
      send_data(@group.sponsor_logo.try(:read), :filename => "sponsor_logo.#{@group.sponsor_logo.extension}", :type => @group.sponsor_logo.content_type,  :disposition => 'inline')
    else
      render :text => ""
    end
  end

  def sponsor_logo_wide
    @group = Group.find_by_slug_or_id(params[:id], :select => [:file_list])
    if @group && @group.has_sponsor_logo_wide?
      send_data(@group.sponsor_logo_wide.try(:read), :filename => "sponsor_logo.#{@group.sponsor_logo_wide.extension}") #, :type => @group.sponsor_logo_wide.content_type,  :disposition => 'inline')
    else
      render :text => "logo error"
    end
  end

  def sponsor_logo_narrow
    @group = Group.find_by_slug_or_id(params[:id], :select => [:file_list])
    if @group && @group.has_sponsor_logo_narrow?
      send_data(@group.sponsor_logo_narrow.try(:read), :filename => "sponsor_logo.#{@group.sponsor_logo_narrow.extension}") #, :type => @group.sponsor_logo_narrow.content_type,  :disposition => 'inline')
    else
      render :text => "logo error"
    end
  end

  def background
    @group = Group.find_by_slug_or_id(params[:id], :select => [:file_list])
    if @group && @group.has_background?
      send_data(@group.background.try(:read), :filename => "background.#{@group.background.extension}", :type => @group.background.content_type,  :disposition => 'inline')
    else
      render :text => "nada"
    end
  end

  def css
    @group = Group.find_by_slug_or_id(params[:id], :select => [:file_list])
    if @group && @group.has_custom_css?
      send_data(@group.custom_css.read, :filename => "custom_theme.css", :type => "text/css")
    else
      render :text => ""
    end
  end

  def group_style
    @group = Group.find_by_slug_or_id(params[:id])

    respond_to do |format|
      format.css
    end

  end

  def group_style_mobile
    @group = Group.find_by_slug_or_id(params[:id])

    respond_to do |format|
      format.css
    end

  end

  def quick_create
    @doctype = Doctype.find_by_slug_or_id(params[:doctype_id])
    @quick_create = @doctype



  end

  def favicon
  end

  def autocomplete_for_group_slug
    @groups = Group.all( :limit => params[:limit] || 20,
                         :fields=> 'slug',
                         :slug =>  /.*#{params[:prefix].downcase.to_s}.*/,
                         :order => "slug desc",
                         :state => "active")

    respond_to do |format|
      format.json {render :json=>@groups}
    end
  end

  def allow_custom_ads
    if current_user.admin?
      @group = Group.find_by_slug_or_id(params[:id])
      @group.has_custom_ads = true
      @group.save
    end
    redirect_to groups_path
  end

  def disallow_custom_ads
    if current_user.admin?
      @group = Group.find_by_slug_or_id(params[:id])
      @group.has_custom_ads = false
      @group.save
    end
    redirect_to groups_path
  end

  protected


  


  def check_permissions
    @group = Group.find_by_slug_or_id(params[:id])

    if @group.nil?
      redirect_to groups_path
    elsif !current_user.owner_of?(@group)
      flash[:error] = t("global.permission_denied")
      redirect_to group_path(@group)
    end
  end
end
