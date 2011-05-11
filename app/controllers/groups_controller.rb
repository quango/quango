class GroupsController < ApplicationController
  skip_before_filter :check_group_access, :only => [:logo, :css, :favicon, :background]
  before_filter :login_required, :except => [:pages, :index, :show, :logo,:sponsor_logo_wide,:sponsor_logo_narrow, :css, :signup_button_css, :favicon, :background]
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
    @group.safe_update(%w[name name_highlight legend description default_tags subdomain logo logo_path favicon_path forum
                          custom_favicon language theme custom_css wysiwyg_editor], params[:group])

    @group.safe_update(%w[isolate domain private], params[:group]) if current_user.admin?

    @group.owner = current_user
    @group.state = "active"

    @group.widgets << TopUsersWidget.new
    @group.widgets << UsersWidget.new

    puts "Starting doctype creation /n"

    doctypes = Array.new

    doctypes << Doctype.new(:name => "news", :doctype => "standard",:create_label => "Add some news",:created_label => "added some news", :group_id => @group.id)
    doctypes << Doctype.new(:name => "thoughts", :doctype => "standard", :create_label => "Share a thought", :created_label => "shared a thought", :group_id => @group.id)
    #doctypes << Doctype.new(:name => "newsfeeds", :doctype => "newsfeed", :create_label => "Add a newsfeed", :hidden => "true", :group_id => @group.id)
    doctypes << Doctype.new(:name => "questions", :doctype => "standard", :create_label => "Ask a question", :created_label => "asked a question", :group_id => @group.id)
    doctypes << Doctype.new(:name => "articles", :doctype => "standard", :create_label => "Write an article", :created_label => "wrote an article", :group_id => @group.id)
    doctypes << Doctype.new(:name => "videos",:has_video => "true", :doctype => "video", :create_label => "Suggest a video", :create_label => "suggested a video", :group_id => @group.id)
    doctypes << Doctype.new(:name => "links",:has_links => "true", :doctype => "bookmark", :create_label => "Share a link", :created_label => "shared a link", :group_id => @group.id)


    doctypes.each do |doctype| 
     doctype.hidden = true
     doctype.save!
     puts "saved #{doctype}"
     #doctype.state = active
     #doctype.save!
     #puts "saved #{doctype} again"
    end

    doctypes.each do |doctype| 
     doctype.hidden = false
     doctype.save!
     puts "saved #{doctype}"
    end

    puts "Finished doctype creation /n"

    #Create standard pages

    puts "Starting standard page creation /n"

    pages = Array.new

    Dir.glob(RAILS_ROOT+"/db/fixtures/pages/*.markdown") do |page_path|
      basename = File.basename(page_path, ".markdown")
      title = basename.gsub(/\.(\w\w)/, "").titleize
      language = $1

      body = File.read(page_path)

      puts "Loading: #{title.inspect} [lang=#{language}]"

      #if Page.count(:title => title, :language => language, :group_id => current_group.id) == 0
        pages << Page.create(:title => title, :language => language, :body => body, :user_id => current_group.owner, :group_id => @group.id)
      #end
    end

    pages.each do |page| 
     page.save!
    end

    puts "Ending standard page creation /n"

    respond_to do |format|
      if @group.save
        @group.add_member(current_user, "owner")
        flash[:notice] = I18n.t("groups.create.flash_notice")
        format.html { redirect_to(domain_url(:custom => @group.domain, :controller => "admin/manage", :action => "properties")) }
        format.json  { render :json => @group.to_json, :status => :created, :location => @group }
      else
        format.html { render :action => "new" }
        format.json { render :json => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.json
  def update
    @group.safe_update(%w[name name_highlight name_link name_highlight_link
                          display_name_i display_name_i_link
                          display_name_ii display_name_ii_link
                          strapline legend 
                          description has_custom_channels custom_channels custom_channel_content default_tags subdomain 
                          has_leaderboard leaderboard_content
                          logo logo_info logo_only
                          forum notification_from notification_email
                          custom_favicon language theme reputation_rewards reputation_constrains
                          hidden has_adult_content registered_only openid_only custom_css wysiwyg_editor fb_button share show_beta_tools
                          publish_label signup_heading leaders_label about_label
                          primary primary_dark secondary tertiary supplementary supplementary_dark supplementary_lite header_bg_image background toolbar_bg toolbar_bg_image
                          robots logo_path favicon_path link_colour  sponsor_logo_wide_info sponsor_logo_narrow_info
                          has_sponsor has_sponsors sponsor_label sponsors_label sponsor_name sponsor_link sponsor_logo_wide sponsor_logo_narrow show_sponsor_description show_sponsor_description_boxheader sponsor_description sponsor_description_boxheader
                          show_signup_button signup_button_title signup_button_description signup_button_label signup_button_footnote signup_custom_css
                         ], params[:group])

    @group.safe_update(%w[isolate show_group_create domain private has_custom_analytics has_custom_html has_custom_js], params[:group]) #if current_user.admin?
    @group.safe_update(%w[analytics_id analytics_vendor], params[:group]) if @group.has_custom_analytics
    @group.custom_html.update_attributes(params[:group][:custom_html] || {}) if @group.has_custom_html

    respond_to do |format|
      if @group.save
        flash[:notice] = 'Group was successfully updated.' # TODO: i18n
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
