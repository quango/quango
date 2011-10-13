class ItemsController < ApplicationController
  
  #require 'rubygems'

  require 'open-uri'

  #require 'nokogiri'
  #require 'hpricot'


  before_filter :login_required, :except => [:new, :create, :index, :show, :tags, :unanswered, :related_items, :tags_for_autocomplete, :retag, :retag_to]
  before_filter :admin_required, :only => [:move, :move_to]
  before_filter :moderator_required, :only => [:close]
  before_filter :check_permissions, :only => [:solve, :unsolve, :destroy]
  before_filter :check_update_permissions, :only => [:edit, :update, :revert]
  before_filter :check_favorite_permissions, :only => [:favorite, :unfavorite] #TODO remove this
  before_filter :set_active_tag
  before_filter :set_active_section
  before_filter :set_default_thumbnail
  before_filter :check_mode
  before_filter :check_age, :only => [:show]
  before_filter :check_retag_permissions, :only => [:retag, :retag_to]

  tabs :default => @mode, :tags => :tags,
       :unanswered => :unanswered, :new => :ask_item

  subtabs :index => [[:fresh, "created_at desc"], [:heat, "hotness desc, views_count desc"], [:relevance, "votes_average desc"], [:activity, "activity_at desc"], [:expert, "created_at desc"]],
          :unanswered => [[:newest, "created_at desc"], [:votes, "votes_average desc"], [:mytags, "created_at desc"]],
          :show => [[:votes, "votes_average desc"], [:oldest, "created_at asc"], [:newest, "created_at desc"]]

  helper :votes
  helper :channels
  helper :items


  def change_doctype

    @item = current_group.items.find_by_slug_or_id(params[:id])
    @doctypes = current_group.doctypes
    @doctype = Doctype.find_by_slug_or_id(params[:doctype_id])

    respond_to do |format|
      #@item.safe_update(%w[doctype_id], params[:item])

      if @item.valid? && @item.save

        flash[:notice] = t(:flash_notice, :scope => "items.update")

        format.html { redirect_to(item_path(@doctype, @item)) }

      else
        format.html { render :action => "change_doctype" }
      #format.html
      end
    end
  end



  def get_video_info
    respond_to do |format|
      format.js do

        #now lets try an array

        results = []

        video_link = []
        video_link << "video_link"
        video_link << params[:item][:video_link]
        results << video_link


        video = VideoInfo.new(video_link.to_s)

        video_id = []
        video_id << "video_id" 
        video_id << video.id
        results << video_id

        video_provider = []
        video_provider << "video_provider" 
        #video_provider << video.provider
        results << video_provider

        video_title = []
        video_title << "video_title" 
        #video_title << video.title.to_s
        results << video_title

        video_description = []
        video_description << "video_description" 
        #video_description << video.description.to_s
        results << video_description

        video_keywords = []
        video_keywords << "video_keywords" 
        #video_keywords << video.keywords.to_s
        results << video_keywords

        video_thumbnail_small = []
        video_thumbnail_small << "video_thumbnail_small" 
        #video_thumbnail_small << video.thumbnail_small.to_s
        results << video_thumbnail_small





        results << "sausage"



        render :json => results
      end
    end
    
  end


  # GET /items
  # GET /items.xml
  def index
    if params[:language] || request.query_string =~ /tags=/
      params.delete(:language)
      head :moved_permanently, :location => url_for(params)
      return
    end

    set_page_title(t("items.index.title"))
    conditions = scoped_conditions(:banned => false)

    if params[:sort] == "hot"
      conditions[:activity_at] = {"$gt" => 21.days.ago}
    end

    @doctypes = current_group.doctypes

    @doctype = @doctypes.find_by_slug_or_id(params[:doctype_id])

    @items = current_group.items #.merge(conditions)

    #@doctype_items = @current_items
 


    @langs_conds = scoped_conditions[:language][:$in]

    if logged_in?
      feed_params = { :feed_token => current_user.feed_token }
    else
      feed_params = {}
    end

    add_feeds_url(url_for({:format => "atom"}.merge(feed_params)), t("feeds.items"))

    if params[:tags]
      add_feeds_url(url_for({:format => "atom", :tags => params[:tags]}.merge(feed_params)),
                    "#{t("feeds.tag")} #{params[:tags].inspect}")
    end

    @tag_cloud = Item.tag_cloud(scoped_conditions, 25)

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render :json => @items.to_json(:except => %w[_keywords watchers slugs]) }
      format.atom
    end
  end

  def feed

    @doctypes = current_group.doctypes
    @doctype = @doctypes.find_by_slug_or_id(params[:doctype_id])
    @items = current_group.items #.merge(conditions)

    if logged_in?
      feed_params = { :feed_token => current_user.feed_token }
    else
      feed_params = {}
    end

    add_feeds_url(url_for({:format => "atom"}.merge(feed_params)), t("feeds.items"))

    if params[:tags]
      add_feeds_url(url_for({:format => "atom", :tags => params[:tags]}.merge(feed_params)),
                    "#{t("feeds.tag")} #{params[:tags].inspect}")
    end

    @tag_cloud = Item.tag_cloud(scoped_conditions, 25)

    respond_to do |format|
      format.atom
    end
  end

  def history
    @item = current_group.items.find_by_slug_or_id(params[:id])

    respond_to do |format|
      format.html
      format.json { render :json => @item.versions.to_json }
    end
  end

  def diff
    @item = current_group.items.find_by_slug_or_id(params[:id])
    @prev = params[:prev]
    @curr = params[:curr]
    if @prev.blank? || @curr.blank? || @prev == @curr
      flash[:error] = "please, select two versions"
      render :history
    else
      if @prev
        @prev = (@prev == "current" ? :current : @prev.to_i)
      end

      if @curr
        @curr = (@curr == "current" ? :current : @curr.to_i)
      end
    end
  end

  def revert
    @item.load_version(params[:version].to_i)
    @doctypes = current_group.doctypes
    @doctype = Doctype.find_by_slug_or_id(params[:doctype_id])

    respond_to do |format|
      format.html
    end
  end

  def related_items
    if params[:id]
      @item = Item.find(params[:id])
    elsif params[:item]
      @item = Item.new(params[:item])
      @item.group_id = current_group.id
    end

    @item.tags += @item.title.downcase.split(",").join(" ").split(" ") if @item.title

    @items = Item.related_items(@item, :page => params[:page],
                                                       :per_page => params[:per_page],
                                                       :order => "answers_count desc",
                                                       :fields => {:_keywords => 0, :watchers => 0, :flags => 0,
                                                                  :close_requests => 0, :open_requests => 0,
                                                                  :versions => 0})

    respond_to do |format|
      format.js do
        render :json => {:html => render_to_string(:partial => "items/item",
                                                   :collection  => @items,
                                                   :locals => {:mini => true, :lite => true})}.to_json
      end
    end
  end

  def unanswered
    if params[:language] || request.query_string =~ /tags=/
      params.delete(:language)
      head :moved_permanently, :location => url_for(params)
      return
    end

    set_page_title(t("items.unanswered.title"))
    conditions = scoped_conditions({:answered_with_id => nil, :banned => false, :closed => false})

    if logged_in?
      if @active_subtab.to_s == "expert"
        @current_tags = current_user.stats(:expert_tags).expert_tags
      elsif @active_subtab.to_s == "mytags"
        @current_tags = current_user.preferred_tags_on(current_group)
      end
    end

    @tag_cloud = Item.tag_cloud(conditions, 25)

    @items = Item.paginate({:order => current_order,
                                    :per_page => 25,
                                    :page => params[:page] || 1,
                                    :fields => {:_keywords => 0, :watchers => 0, :flags => 0,
                                                :close_requests => 0, :open_requests => 0,
                                                :versions => 0}
                                   }.merge(conditions))

    respond_to do |format|
      format.html # unanswered.html.erb
      format.json  { render :json => @items.to_json(:except => %w[_keywords slug watchers]) }
    end
  end

  def tags
    conditions = scoped_conditions({:answered_with_id => nil, :banned => false})
    if params[:q].blank?
      @tag_cloud = Item.tag_cloud(conditions)
    else
      @tag_cloud = Item.find_tags(/^#{Regexp.escape(params[:q])}/, conditions)
    end
    respond_to do |format|
      format.html do
        set_page_title(t("layouts.application.tags"))
      end
      format.js do
        html = render_to_string(:partial => "tag_table", :object => @tag_cloud)
        render :json => {:html => html}
      end
      format.json  { render :json => @tag_cloud.to_json }
    end
  end

  def tags_for_autocomplete
    respond_to do |format|
      format.js do
        result = []
        if q = params[:tag]
          result = Item.find_tags(/^#{Regexp.escape(q.downcase)}/i,
                                      :group_id => current_group.id,
                                      :banned => false)
        end

        results = result.map do |t|
          {:caption => "#{t["name"]} (#{t["count"].to_i})", :value => t["name"]}
        end
        # if no results, show default tags
        if results.empty?
          results = current_group.default_tags.map  {|tag|{:value=> tag, :caption => tag}}
        end
        render :json => results
      end
    end
  end

  # GET /items/1
  # GET /items/1.xml
  def show

    @item = Item.find_by_slug_or_id(params[:id])

    target_section = Doctype.find_by_slug_or_id(@item.doctype_id)
    @section = target_section


    @doctypes = current_group.doctypes
    @doctype = current_group.doctypes.find_by_slug_or_id(params[:doctype_id])

    if params[:language]
      params.delete(:language)
      head :moved_permanently, :location => url_for(params)
      return
    end

    if @item.meta_author = "Null"
      @item.meta_author = @item.user.display_name
    end

    #@section = Section.find(@item.section.id)

    @images = Image.all
    
    @default_thumbnail = Image.find(@item.default_thumbnail)

    current_order = "updated_at desc"
    conditions = scoped_conditions(:banned => false)

    @items = current_group.items.sort_by(&:activity_at).reverse

    #@items = Item.all({:order => current_order}.merge(conditions))

    @tag_cloud = Item.tag_cloud(:_id => @item.id, :banned => false)

    options = {:per_page => 25, :page => params[:page] || 1,
               :order => current_order, :banned => false}
    options[:_id] = {:$ne => @item.answer_id} if @item.answer_id
    options[:fields] = {:_keywords => 0}

    @answers = @item.answers.paginate(options)

    @answer = Answer.new(params[:answer])




    if @item.user != current_user && !is_bot?
      @item.viewed!(request.remote_ip)

      if (@item.views_count % 10) == 0
        sweep_item(@item)
      end
    end

    set_page_title(@item.title)
    add_feeds_url(url_for(:format => "atom"), t("feeds.item"))

    respond_to do |format|

      format.html { Magent.push("actors.judge", :on_view_item, @item.id) }
      format.json  { render :json => @item.to_json(:except => %w[_keywords slug watchers]) }
      format.atom
    end
  end

  # GET /items/new
  # GET /items/new.xml
  def new
    @item = Item.new(params[:item])

    @doctypes = current_group.doctypes
    @doctype = @doctypes.find_by_slug_or_id(params[:doctype_id])

    @item.doctype_id = @doctype.id

    #@item.tags = current_group.default_tags.first

    respond_to do |format|
      format.html # new.html.erb
      format.json  { render :json => @item.to_json }
    end
  end

  # GET /items/1/edit
  def edit

    @doctypes = current_group.doctypes
    @doctype = @doctypes.find_by_slug_or_id(params[:doctype_id])

  end

  def images
    return 


  end

  # POST /items
  # POST /items.xml
  def create
    @item = Item.new
    @item.safe_update(%w[doctype_id section node mode title description bookmark video_link article_link main_image main_thumbnail images body language tags wiki anonymous meta_author], params[:item])
    @item.group = current_group
    @item.user = current_user

    @doctypes = current_group.doctypes
    @doctype = @doctypes.find_by_slug_or_id(params[:doctype_id])

    @item.doctype_id = @doctype.id

    @item.meta_author = current_user.display_name
    @item.meta_title = @item.title
    @item.meta_description = @item.description
    @item.meta_publisher = current_group.domain
    @item.meta_abstract = @item.abstract

    keywords_array = Array.new

    #keywords_array = keywords_array << @item.category

   
    #doc.keywords.each do |tag|
      #keywords_array = keywords_array << tag
    #end

    #@item.tags = keywords_array





    if @item.video_link?

      video = VideoInfo.new(@item.video_link)
      @item.title = video.title
      @item.body = video.description
      @item.tags = video.provider << ", " << video.keywords[0..7]
      @item.video_thumbnail = video.thumbnail_small
      #@item.meta_author = video.author.to_s
      @item.meta_title = video.title
      @item.meta_description = @item.description
      @item.meta_publisher = video.provider
      @item.meta_abstract = @item.abstract
      @item.meta_keywords = video.keywords
      #image.image = video_thumbnail_small

    end

    if @item.article_link?


      if current_group.has_alchemy?

        #grab the stuff through alchemy

      else


require 'pismo'

# Load a Web page (you could pass an IO object or a string with existing HTML data along, as you prefer)
      doc = Pismo::Document.new(@item.article_link, :reader => :cluster)



      @item.title = doc.title
      @item.description = doc.description

      if doc.author
        @item.article_link_author = doc.author
      else
        @item.article_link_author = ""
      end


      publisher = URI.parse(@item.article_link).to_s

      @item.article_link_publisher = get_host_without_www(@item.article_link)





      #@item.tags = doc.keywords.to_s

      #tag_array = Array.new

        #doc.keywords[0..4].each do |tag|
      
      #temp_tag = tag[0]


        #tag_array << tag

        #end

      #tag_array.each do |clean_tag|

      #@item.tags = tag_array

      #end

      #@item.tags = tag_array

      #body = "Standard link body: #{pass_title}"

      quote_body = doc.body.to_s


      @item.body = shorten(quote_body, 256)

      @item.meta_author = @item.user
      @item.meta_title = @item.title
      @item.meta_description = @item.description
      @item.meta_publisher = current_group.domain
      @item.meta_abstract = @item.abstract
      @item.meta_keywords = doc.keywords

      end
    end

    if !logged_in?
      if recaptcha_valid? && params[:user]
        @user = User.first(:email => params[:user][:email])
        if @user.present?
          if !@user.anonymous
            flash[:notice] = "The user is already registered, please log in"
            return create_draft!
          else
            @item.user = @user
          end
        else
          @user = User.new(:anonymous => true, :login => "Anonymous")
          @user.safe_update(%w[name email website], params[:user])
          @user.login = @user.name if @user.name.present?
          @user.save!
          @item.user = @user
        end
      elsif !AppConfig.recaptcha["activate"]
        return create_draft!
      end
    end

    respond_to do |format|
      if (logged_in? ||  (@item.user.valid? && recaptcha_valid?)) && @item.save

        sweep_item_views

        current_group.tag_list.add_tags(*@item.tags)
        #@item.meta_keywords = @item.category << ", " << @item.tags
  
        


        unless @item.anonymous
          @item.user.stats.add_item_tags(*@item.tags)
          @item.user.on_activity(:ask_item, current_group)
          Magent.push("actors.judge", :on_ask_item, @item.id)

          # TODO: move to magent
          users = User.find_experts(@item.tags, [@item.language],
                                                    :except => [@item.user.id],
                                                    :group_id => current_group.id)
          followers = @item.user.followers(:group_id => current_group.id, :languages => [@item.language])

          (users - followers).each do |u|
            if !u.email.blank?
              Notifier.deliver_give_advice(u, current_group, @item, false)
            end
          end

          followers.each do |u|
            if !u.email.blank?
              Notifier.deliver_give_advice(u, current_group, @item, true)
            end
          end
        end

        current_group.on_activity(:ask_item)
        flash[:notice] = "Thanks, you have just " + @doctype.created_label.to_s


        if @item.video_link?
          format.html { redirect_to item_path(@doctype, @item)}
        elsif @item.article_link?
          format.html { redirect_to item_path(@doctype, @item)}
        else
          format.html { redirect_to item_images_path(@doctype, @item)}
        end




        format.json { render :json => @item.to_json(:except => %w[_keywords watchers]), :status => :created}
      else
        @item.errors.add(:captcha, "is invalid") unless recaptcha_valid?
        format.html { render :action => "new" }
        format.json { render :json => @item.errors+@item.user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /items/1
  # PUT /items/1.xml
  def update
    respond_to do |format|
      @item.safe_update(%w[meta_author category doctype_id node mode title description bookmark video_link main_thumbnail images body language tags wiki adult_content version_message  anonymous], params[:item])
      @item.updated_by = current_user
      @item.last_target = @item
      #@item.section = @active_section
      #@item.slugs << @item.slug
      #@item.send(:generate_slug)

      #sane_title = params[:item][:title]
      #sane_title_down = sane_title.downcase
      #sane_title_capitals = sane_title_down.capitalize
      @item.title = params[:item][:title]
      @item.category = params[:item][:category]
      @item.doctype_id = params[:item][:doctype_id]

      @doctypes = current_group.doctypes
      @doctype = @doctypes.find_by_slug_or_id(params[:item][:doctype_id])

     #quote_body = doc.body.to_s


     # @item.body = shorten(quote_body, 256)

      if @item.meta_author == "Null"
        @item.meta_author = @item.user.display_name
      end

      #@item.meta_title = @item.title


      #@item.meta_description = @item.description

      #@item.meta_publisher = current_group.domain
      #@item.meta_abstract = @item.abstract
      #@item.meta_keywords = doc.keywords


      if @item.valid? && @item.save
        sweep_item_views
        sweep_item(@item)

        flash[:notice] = t(:flash_notice, :scope => "items.update")

        format.html { redirect_to(item_path(@doctype, @item)) }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.json  { render :json => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def meta
    respond_to do |format|
     # @item = Item.find_by_slug_or_id(params[:id])
     @doctypes = current_group.doctypes
     @doctype = @doctypes.find_by_slug_or_id(params[:doctype_id])

     # @item.safe_update(%w[meta_author], params[:item])

      if @item.meta_author == "Null"
        @item.meta_author = @item.user.display_name
      end

      if @item.meta_title == "Null"
        @item.meta_title = @item.title
      end

      if @item.meta_description == "Null"
        @item.meta_description = @item.description
      end

      if @item.meta_keywords == "Null"
        @item.meta_keywords = @item.tags
      end

      unless @item.valid? && @item.save
        sweep_item_views
        sweep_item(@item)

        flash[:notice] = t(:flash_notice, :scope => "items.update")

        format.html { redirect_to(item_path(@doctype, @item)) }
        format.json  { head :ok }
      else
        format.html { render :action => "meta" }
        format.json  { render :json => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1
  # DELETE /items/1.xml
  def destroy
    if @item.user_id == current_user.id
      @item.user.update_reputation(:delete_item, current_group)
    end
    sweep_item(@item)
    sweep_item_views
    @item.destroy

    Magent.push("actors.judge", :on_destroy_item, current_user.id, @item.attributes)

    respond_to do |format|
      format.html { redirect_to(items_url) }
      format.json  { head :ok }
    end
  end

  def solve
    @answer = @item.answers.find(params[:answer_id])
    @item.answer = @answer
    @item.accepted = true
    @item.answered_with = @answer if @item.answered_with.nil?

    @doctype = current_group.doctypes.find_by_slug_or_id(@item.doctype_id)

    respond_to do |format|
      if @item.save
        sweep_item(@item)

        current_user.on_activity(:close_item, current_group)
        if current_user != @answer.user
          @answer.user.update_reputation(:answer_picked_as_solution, current_group)
        end

        Magent.push("actors.judge", :on_item_solved, @item.id, @answer.id)

        flash[:notice] = t(:flash_notice, :scope => "items.solve")
        format.html { redirect_to item_path(@doctype, @item) }
        format.json  { head :ok }
      else
        @tag_cloud = Item.tag_cloud(:_id => @item.id, :banned => false)
        options = {:per_page => 25, :page => params[:page] || 1,
                   :order => current_order, :banned => false}
        options[:_id] = {:$ne => @item.answer_id} if @item.answer_id
        @answers = @item.answers.paginate(options)
        @answer = Answer.new

        format.html { render :action => "show" }
        format.json  { render :json => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def unsolve
    @answer_id = @item.answer.id
    @answer_owner = @item.answer.user

    @doctype = current_group.doctypes.find_by_slug_or_id(@item.doctype_id)

    @item.answer = nil
    @item.accepted = false
    @item.answered_with = nil if @item.answered_with == @item.answer

    respond_to do |format|
      if @item.save
        sweep_item(@item)

        flash[:notice] = t(:flash_notice, :scope => "items.unsolve")
        current_user.on_activity(:reopen_item, current_group)
        if current_user != @answer_owner
          @answer_owner.update_reputation(:answer_unpicked_as_solution, current_group)
        end

        Magent.push("actors.judge", :on_item_unsolved, @item.id, @answer_id)

        format.html { redirect_to item_path(@doctype, @item) }
        format.json  { head :ok }
      else
        @tag_cloud = Item.tag_cloud(:_id => @item.id, :banned => false)
        options = {:per_page => 25, :page => params[:page] || 1,
                   :order => current_order, :banned => false}
        options[:_id] = {:$ne => @item.answer_id} if @item.answer_id
        @answers = @item.answers.paginate(options)
        @answer = Answer.new

        format.html { render :action => "show" }
        format.json  { render :json => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def close
    @item = Item.find_by_slug_or_id(params[:id])

    @item.closed = true
    @item.closed_at = Time.zone.now
    @item.close_reason_id = params[:close_request_id]

    respond_to do |format|
      if @item.save
        sweep_item(@item)

        format.html { redirect_to item_path(@item) }
        format.json { head :ok }
      else
        flash[:error] = @item.errors.full_messages.join(", ")
        format.html { redirect_to item_path(@item) }
        format.json { render :json => @item.errors, :status => :unprocessable_entity  }
      end
    end
  end

  def open
    @item = Item.find_by_slug_or_id(params[:id])

    @item.closed = false
    @item.close_reason_id = nil

    respond_to do |format|
      if @item.save
        sweep_item(@item)

        format.html { redirect_to item_path(@item) }
        format.json { head :ok }
      else
        flash[:error] = @item.errors.full_messages.join(", ")
        format.html { redirect_to item_path(@item) }
        format.json { render :json => @item.errors, :status => :unprocessable_entity  }
      end
    end
  end

  def favorite
    @favorite = Favorite.new
    @favorite.item = @item
    @favorite.user = current_user
    @favorite.group = @item.group

    @item.add_watcher(current_user)

    if (@item.user_id != current_user.id) && current_user.notification_opts.activities
      Notifier.deliver_favorited(current_user, @item.group, @item)
    end

    respond_to do |format|
      if @favorite.save
        @item.add_favorite!(@favorite, current_user)
        flash[:notice] = t("favorites.create.success")
        format.html { redirect_to(item_path(@item)) }
        format.json { head :ok }
        format.js {
          render(:json => {:success => true,
                   :message => flash[:notice], :increment => 1 }.to_json)
        }
      else
        flash[:error] = @favorite.errors.full_messages.join("**")
        format.html { redirect_to(item_path(@item)) }
        format.js {
          render(:json => {:success => false,
                   :message => flash[:error], :increment => 0 }.to_json)
        }
        format.json { render :json => @favorite.errors, :status => :unprocessable_entity }
      end
    end
  end

  def unfavorite
    @favorite = current_user.favorite(@item)
    if @favorite
      if current_user.can_modify?(@favorite)
        @item.remove_favorite!(@favorite, current_user)
        @favorite.destroy
        @item.remove_watcher(current_user)
      end
    end
    flash[:notice] = t("unfavorites.create.success")
    respond_to do |format|
      format.html { redirect_to(item_path(@item)) }
      format.js {
        render(:json => {:success => true,
                 :message => flash[:notice], :increment => -1 }.to_json)
      }
      format.json  { head :ok }
    end
  end

  def bump
    @item = Item.find_by_slug_or_id(params[:id])
    @item.last_target = @item  
    @item.save

    flash[:notice] = "#{@item.title} bumped"
    respond_to do |format|
      format.html { redirect_to(item_path(@item.doctype, @item)) }
      format.js {
        render(:json => {:success => true,
                 :message => flash[:notice] }.to_json)
      }
      format.json { head :ok }
    end
  end



  def watch
    @item = Item.find_by_slug_or_id(params[:id])
    @item.add_watcher(current_user)
    flash[:notice] = "You are now watching this item - any new comments will be emailed to you"
    respond_to do |format|
      format.html {redirect_to item_path(@item.doctype, @item)}
      format.js {
        render(:json => {:success => true,
                 :message => flash[:notice] }.to_json)
      }
      format.json { head :ok }
    end
  end




  def unwatch
    @item = Item.find_by_slug_or_id(params[:id])
    @item.remove_watcher(current_user)
    flash[:notice] = t("items.unwatch.success")
    respond_to do |format|
      format.html {redirect_to item_path(@item)}
      format.js {
        render(:json => {:success => true,
                 :message => flash[:notice] }.to_json)
      }
      format.json { head :ok }
    end
  end

  def move
    @item = Item.find_by_slug_or_id(params[:id])
    render
  end

  def move_to
    @group = Group.find_by_slug_or_id(params[:item][:group])
    @item = Item.find_by_slug_or_id(params[:id])

    if @group
      @item.group = @group

      if @item.save
        sweep_item(@item)

        Answer.set({"item_id" => @item.id}, {"group_id" => @group.id})
      end
      flash[:notice] = t("items.move_to.success", :group => @group.name)
      redirect_to item_path(@item)
    else
      flash[:error] = t("items.move_to.group_dont_exists",
                        :group => params[:item][:group])
      render :move
    end
  end

  def retag_to
    @item = Item.find_by_slug_or_id(params[:id])
    @doctype = current_group.doctypes.find_by_slug_or_id(params[:doctype_id])


    @item.tags = params[:item][:tags]
    @item.updated_by = current_user
    @item.last_target = @item

    if @item.save
      sweep_item(@item)

      if (Time.now - @item.created_at) < 8.days
        @item.on_activity(true)
      end

      #Magent.push("actors.judge", :on_retag_item, @item.id, current_user.id)

      flash[:notice] = t("items.retag_to.success", :group => @item.group.name)
      respond_to do |format|
        format.html {redirect_to item_path(@doctype, @item)}
        format.js {
          render(:json => {:success => true,
                   :message => flash[:notice], :tags => @item.tags }.to_json)
        }
      end
    else
      flash[:error] = t("items.retag_to.failure",
                        :group => params[:item][:group])

      respond_to do |format|
        format.html {render :retag}
        format.js {
          render(:json => {:success => false,
                   :message => flash[:error] }.to_json)
        }
      end
    end
  end


  def retag
    @item = current_group.items.find_by_slug_or_id(params[:id])
    @doctypes = current_group.doctypes
    @doctype = @doctypes.find_by_slug_or_id(params[:doctype_id])
    respond_to do |format|
      format.html {render}
      format.js {
        render(:json => {:success => true, :html => render_to_string(:partial => "items/retag_form",
                                                   :member  => @item)}.to_json)
      }
    end
  end

  def shorten(string, count = 30)
	  if string.length >= count 
		  shortened = string[0, count]
		  splitted = shortened.split(/\s/)
		  words = splitted.length
		  splitted[0, words-1].join(" ") + ' ...'
	  else 
		  string
	  end
  end



  protected


  def get_host_without_www(url)
    uri = URI.parse(url)
    uri = URI.parse("http://#{url}") if uri.scheme.nil?
    host = uri.host.downcase
    host.start_with?('www.') ? host[4..-1] : host
  end

  def check_mode

    @item = Item.find_by_slug_or_id(params[:id])

    if @item.nil?
     @mode = "nil detected"
    end

     @mode = params[:mode]
     @mode

  end

  def check_permissions
    @item = Item.find_by_slug_or_id(params[:id])

    if @item.nil?
      redirect_to items_path
    elsif !(current_user.can_modify?(@item) ||
           (params[:action] != 'destroy' && @item.can_be_deleted_by?(current_user)) ||
           current_user.owner_of?(@item.group)) # FIXME: refactor
      flash[:error] = t("global.permission_denied")
      redirect_to item_path(@item)
    end
  end

  def check_update_permissions
    @item = current_group.items.find_by_slug_or_id(params[:id])
    allow_update = true
    unless @item.nil?
      if !current_user.can_modify?(@item)
        if @item.wiki
          if !current_user.can_edit_wiki_post_on?(@item.group)
            allow_update = false
            reputation = @item.group.reputation_constrains["edit_wiki_post"]
            flash[:error] = I18n.t("users.messages.errors.reputation_needed",
                                        :min_reputation => reputation,
                                        :action => I18n.t("users.actions.edit_wiki_post"))
          end
        else
          if !current_user.can_edit_others_posts_on?(@item.group)
            allow_update = false
            reputation = @item.group.reputation_constrains["edit_others_posts"]
            flash[:error] = I18n.t("users.messages.errors.reputation_needed",
                                        :min_reputation => reputation,
                                        :action => I18n.t("users.actions.edit_others_posts"))
          end
        end
        return redirect_to item_path(@item) if !allow_update
      end
    else
      return redirect_to items_path
    end
  end

  def check_favorite_permissions
    @item = current_group.items.find_by_slug_or_id(params[:id])
    unless logged_in?
      flash[:error] = t(:unauthenticated, :scope => "favorites.create")
      respond_to do |format|
        format.html do
          flash[:error] += ", [#{t("global.please_login")}](#{new_user_session_path})"
          redirect_to item_path(@item)
        end
        format.js do
          flash[:error] += ", <a href='#{new_user_session_path}'> #{t("global.please_login")} </a>"
          render(:json => {:status => :error, :message => flash[:error] }.to_json)
        end
        format.json do
          flash[:error] += ", <a href='#{new_user_session_path}'> #{t("global.please_login")} </a>"
          render(:json => {:status => :error, :message => flash[:error] }.to_json)
        end
      end
    end
  end


  def check_retag_permissions
    @item = Item.find_by_slug_or_id(params[:id])
    unless logged_in? && (current_user.can_retag_others_items_on?(current_group) ||  current_user.can_modify?(@item))
      reputation = @item.group.reputation_constrains["retag_others_items"]
      if !logged_in?
        flash[:error] = t("items.show.unauthenticated_retag")
      else
        flash[:error] = I18n.t("users.messages.errors.reputation_needed",
                               :min_reputation => reputation,
                               :action => I18n.t("users.actions.retag_others_items"))
      end
      respond_to do |format|
        format.html {redirect_to @item}
        format.js {
          render(:json => {:success => false,
                   :message => flash[:error] }.to_json)
        }
      end
    end
  end

  def set_default_thumbnail
#    @item = Item.find_by_slug_or_id(params[:id])
#    @default_thumbnail = @item.default_thumbnail
#    @default_thumbnail
  end

  def set_active_tag
    @active_tag = "tag_#{params[:tags]}" if params[:tags]
    @active_tag
  end

  def set_active_section

     @active_section = params[:doctype_id]

     #@item = Item.find_by_slug_or_id(params[:id])


     @doctypes = current_group.doctypes
        
  
     @doctypes.each do |doctype|
      
     if doctype.name == @active_section
        @active_doctype = doctype
     end

     end

     #@section = Section.find


     @active_section
  end

  def check_age
    @item = current_group.items.find_by_slug_or_id(params[:id])

    if @item.nil?
      @item = current_group.items.first(:slugs => params[:id], :select => [:_id, :slug])
      if @item.present?
        head :moved_permanently, :location => item_url(@item.doctype, @item)
        return
      elsif params[:id] =~ /^(\d+)/ && (@item = current_group.items.first(:se_id => $1, :select => [:_id, :slug]))
        head :moved_permanently, :location => item_url(@item.doctype, @item)
      else
        raise PageNotFound
      end
    end

    return if session[:age_confirmed] || is_bot? || !@item.adult_content

    if !logged_in? || (Date.today.year.to_i - (current_user.birthday || Date.today).year.to_i) < 18
      render :template => "welcome/confirm_age"
    end
  end

  def create_draft!
    draft = Draft.create!(:item => @item)
    session[:draft] = draft.id
    login_required
  end
end
