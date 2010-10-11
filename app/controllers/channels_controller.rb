class ChannelsController < ApplicationController
  before_filter :login_required, :except => [:new, :create, :index, :show, :tags, :unanswered, :related_items, :tags_for_autocomplete, :retag, :retag_to]
  before_filter :admin_required, :only => [:move, :move_to]
  before_filter :moderator_required, :only => [:close]
  before_filter :check_permissions, :only => [:solve, :unsolve, :destroy]
  before_filter :check_update_permissions, :only => [:edit, :update, :revert]
  before_filter :check_favorite_permissions, :only => [:favorite, :unfavorite] #TODO remove this
  before_filter :set_active_tag
  before_filter :check_age, :only => [:show]
  before_filter :check_retag_permissions, :only => [:retag, :retag_to]

 # tabs :default => :channels, :tags => :tags,
  tabs :default => [:channels.to_s],
       :unanswered => :unanswered, :new => :ask_item

  subtabs :index => [[:newest, "created_at desc"], [:hot, "hotness desc, views_count desc"], [:votes, "votes_average desc"], [:activity, "activity_at desc"], [:expert, "created_at desc"]],
          :unanswered => [[:newest, "created_at desc"], [:votes, "votes_average desc"], [:mytags, "created_at desc"]],
          :show => [[:votes, "votes_average desc"], [:oldest, "created_at asc"], [:newest, "created_at desc"]]
  helper :votes

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
      conditions[:activity_at] = {"$gt" => 5.days.ago}
    end

    @items = Item.paginate({:per_page => 25, :page => params[:page] || 1,
                                   :order => current_order,
                                   :fields => (Item.keys.keys - ["_keywords", "watchers"])}.
                                               merge(conditions))

    @langs_conds = scoped_conditions[:language][:$in]

    if logged_in?
      feed_params = { :feed_token => current_user.feed_token }
    else
      feed_params = {  :lang => I18n.locale,
                          :mylangs => current_languages }
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

    @item.tags += @item.title.downcase.split(",").join(" ").split(" ")

    @items = Item.related_items(@item, :page => params[:page],
                                                       :per_page => params[:per_page],
                                                       :order => "answers_count desc")

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
                                    :fields => (Item.keys.keys - ["_keywords", "watchers"])
                                   }.merge(conditions))

    respond_to do |format|
      format.html # unanswered.html.erb
      format.json  { render :json => @items.to_json(:except => %w[_keywords slug watchers]) }
    end
  end

  def taggies
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
      format.xml  { render :json => @tag_cloud.to_xml }
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
    if params[:language]
      params.delete(:language)
      head :moved_permanently, :location => url_for(params)
      return
    end

    @tag_cloud = Item.tag_cloud(:_id => @item.id, :banned => false)
    options = {:per_page => 25, :page => params[:page] || 1,
               :order => current_order, :banned => false}
    options[:_id] = {:$ne => @item.answer_id} if @item.answer_id
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
    respond_to do |format|
      format.html # new.html.erb
      format.json  { render :json => @item.to_json }
    end
  end

  # GET /items/1/edit
  def edit
  end

  # POST /items
  # POST /items.xml
  def create
    @item = Item.new
    @item.safe_update(%w[title body language tags wiki], params[:item])
    @item.group = current_group
    @item.user = current_user

    if !logged_in?
      if recaptcha_valid? && params[:user]
        @user = User.find(:email => params[:user][:email])
        if @user.present?
          if !@user.anonymous
            flash[:notice] = "The user is already registered, please log in"
            return create_draft!
          end
        else
          @user = User.new(:anonymous => true, :login => "Anonymous")
          @user.safe_update(%w[name email website], params[:user])
          @user.login = @user.name if @user.name.present?
          @user.save
          @item.user = @user
        end
      elsif !AppConfig.recaptcha["activate"]
        return create_draft!
      end
    end

    respond_to do |format|
      if (recaptcha_valid? || logged_in?) && @item.user.valid? && @item.save
        sweep_item_views

        @item.user.stats.add_item_tags(*@item.tags)
        current_group.tag_list.add_tags(*@item.tags)

        @item.user.on_activity(:ask_item, current_group)
        current_group.on_activity(:ask_item)

        Magent.push("actors.judge", :on_ask_item, @item.id)

        flash[:notice] = t(:flash_notice, :scope => "items.create")

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

        format.html { redirect_to(item_path(@item)) }
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
      @item.safe_update(%w[title body language tags wiki adult_content version_message], params[:item])
      @item.updated_by = current_user
      @item.last_target = @item

      @item.slugs << @item.slug
      @item.send(:generate_slug)

      if @item.valid? && @item.save
        sweep_item_views
        sweep_item(@item)

        flash[:notice] = t(:flash_notice, :scope => "items.update")
        format.html { redirect_to(item_path(@item)) }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
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

    respond_to do |format|
      if @item.save
        sweep_item(@item)

        current_user.on_activity(:close_item, current_group)
        if current_user != @answer.user
          @answer.user.update_reputation(:answer_picked_as_solution, current_group)
        end

        Magent.push("actors.judge", :on_item_solved, @item.id, @answer.id)

        flash[:notice] = t(:flash_notice, :scope => "items.solve")
        format.html { redirect_to item_path(@item) }
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

        format.html { redirect_to item_path(@item) }
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

  def watch
    @item = Item.find_by_slug_or_id(params[:id])
    @item.add_watcher(current_user)
    flash[:notice] = t("items.watch.success")
    respond_to do |format|
      format.html {redirect_to item_path(@item)}
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

    @item.tags = params[:item][:tags]
    @item.updated_by = current_user
    @item.last_target = @item

    if @item.save
      sweep_item(@item)

      if (Time.now - @item.created_at) < 8.days
        @item.on_activity(true)
      end

      Magent.push("actors.judge", :on_retag_item, @item.id, current_user.id)

      flash[:notice] = t("items.retag_to.success", :group => @item.group.name)
      respond_to do |format|
        format.html {redirect_to item_path(@item)}
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
    @item = Item.find_by_slug_or_id(params[:id])
    respond_to do |format|
      format.html {render}
      format.js {
        render(:json => {:success => true, :html => render_to_string(:partial => "items/retag_form",
                                                   :member  => @item)}.to_json)
      }
    end
  end

  protected
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

  def set_active_tag
    @active_tag = "tag_#{params[:tags]}" if params[:tags]
    @active_tag
  end

  def check_age
    @item = current_group.items.find_by_slug_or_id(params[:id])

    if @item.nil?
      @item = current_group.items.first(:slugs => params[:id], :select => [:_id, :slug])
      if @item.present?
        head :moved_permanently, :location => item_url(@item)
        return
      elsif params[:id] =~ /^(\d+)/ && (@item = current_group.items.first(:se_id => $1, :select => [:_id, :slug]))
        head :moved_permanently, :location => item_url(@item)
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
