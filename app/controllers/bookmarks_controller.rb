class BookmarksController < ApplicationController
  before_filter :login_required, :except => [:new, :create, :index, :show, :tags, :unanswered, :related_bookmarks, :tags_for_autocomplete, :retag, :retag_to]
  before_filter :admin_required, :only => [:move, :move_to]
  before_filter :moderator_required, :only => [:close]
  before_filter :check_permissions, :only => [:solve, :unsolve, :destroy]
  before_filter :check_update_permissions, :only => [:edit, :update, :revert]
  before_filter :check_favorite_permissions, :only => [:favorite, :unfavorite] #TODO remove this
  before_filter :set_active_tag
  before_filter :check_age, :only => [:show]
  before_filter :check_retag_permissions, :only => [:retag, :retag_to]

  tabs :default => :bookmarks, :tags => :tags,
       :unanswered => :unanswered, :new => :contribute

  subtabs :index => [[:newest, "created_at desc"], [:hot, "hotness desc, views_count desc"], [:votes, "votes_average desc"], [:activity, "activity_at desc"], [:expert, "created_at desc"]],
          :unanswered => [[:newest, "created_at desc"], [:votes, "votes_average desc"], [:mytags, "created_at desc"]],
          :show => [[:votes, "votes_average desc"], [:oldest, "created_at asc"], [:newest, "created_at desc"]]
  helper :votes
  helper :channels

  # GET /bookmarks
  # GET /bookmarks.xml
  def index
    if params[:language] || request.query_string =~ /tags=/
      params.delete(:language)
      head :moved_permanently, :location => url_for(params)
      return
    end

    set_page_title(t("bookmarks.index.title"))
    conditions = scoped_conditions(:banned => false)

    if params[:sort] == "hot"
      conditions[:activity_at] = {"$gt" => 5.days.ago}
    end

    @bookmarks = Bookmark.paginate({:per_page => 25, :page => params[:page] || 1,
                                   :order => current_order,
                                   :fields => (Bookmark.keys.keys - ["_keywords", "watchers"])}.
                                               merge(conditions))

    @langs_conds = scoped_conditions[:language][:$in]

    if logged_in?
      feed_params = { :feed_token => current_user.feed_token }
    else
      feed_params = {  :lang => I18n.locale,
                          :mylangs => current_languages }
    end
    add_feeds_url(url_for({:format => "atom"}.merge(feed_params)), t("feeds.bookmarks"))
    if params[:tags]
      add_feeds_url(url_for({:format => "atom", :tags => params[:tags]}.merge(feed_params)),
                    "#{t("feeds.tag")} #{params[:tags].inspect}")
    end
    @tag_cloud = Bookmark.tag_cloud(scoped_conditions, 25)

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render :json => @bookmarks.to_json(:except => %w[_keywords watchers slugs]) }
      format.atom
    end
  end


  def history
    @bookmark = current_group.bookmarks.find_by_slug_or_id(params[:id])

    respond_to do |format|
      format.html
      format.json { render :json => @bookmark.versions.to_json }
    end
  end

  def diff
    @bookmark = current_group.bookmarks.find_by_slug_or_id(params[:id])
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
    @bookmark.load_version(params[:version].to_i)

    respond_to do |format|
      format.html
    end
  end

  def related_bookmarks
    if params[:id]
      @bookmark = Bookmark.find(params[:id])
    elsif params[:bookmark]
      @bookmark = Bookmark.new(params[:bookmark])
      @bookmark.group_id = current_group.id
    end

    @bookmark.tags += @bookmark.title.downcase.split(",").join(" ").split(" ")

    @bookmarks = Bookmark.related_bookmarks(@bookmark, :page => params[:page],
                                                       :per_page => params[:per_page],
                                                       :order => "answers_count desc")

    respond_to do |format|
      format.js do
        render :json => {:html => render_to_string(:partial => "bookmarks/bookmark",
                                                   :collection  => @bookmarks,
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

    set_page_title(t("bookmarks.unanswered.title"))
    conditions = scoped_conditions({:answered_with_id => nil, :banned => false, :closed => false})

    if logged_in?
      if @active_subtab.to_s == "expert"
        @current_tags = current_user.stats(:expert_tags).expert_tags
      elsif @active_subtab.to_s == "mytags"
        @current_tags = current_user.preferred_tags_on(current_group)
      end
    end

    @tag_cloud = Bookmark.tag_cloud(conditions, 25)

    @bookmarks = Bookmark.paginate({:order => current_order,
                                    :per_page => 25,
                                    :page => params[:page] || 1,
                                    :fields => (Bookmark.keys.keys - ["_keywords", "watchers"])
                                   }.merge(conditions))

    respond_to do |format|
      format.html # unanswered.html.erb
      format.json  { render :json => @bookmarks.to_json(:except => %w[_keywords slug watchers]) }
    end
  end

  def tags
    conditions = scoped_conditions({:answered_with_id => nil, :banned => false})
    if params[:q].blank?
      @tag_cloud = Bookmark.tag_cloud(conditions)
    else
      @tag_cloud = Bookmark.find_tags(/^#{Regexp.escape(params[:q])}/, conditions)
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
          result = Bookmark.find_tags(/^#{Regexp.escape(q.downcase)}/i,
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

  # GET /bookmarks/1
  # GET /bookmarks/1.xml
  def show
    if params[:language]
      params.delete(:language)
      head :moved_permanently, :location => url_for(params)
      return
    end

    @tag_cloud = Bookmark.tag_cloud(:_id => @bookmark.id, :banned => false)
    options = {:per_page => 25, :page => params[:page] || 1,
               :order => current_order, :banned => false}
    options[:_id] = {:$ne => @bookmark.answer_id} if @bookmark.answer_id
    @answers = @bookmark.answers.paginate(options)

    @answer = Answer.new(params[:answer])

    if @bookmark.user != current_user && !is_bot?
      @bookmark.viewed!(request.remote_ip)

      if (@bookmark.views_count % 10) == 0
        sweep_bookmark(@bookmark)
      end
    end

    set_page_title(@bookmark.title)
    add_feeds_url(url_for(:format => "atom"), t("feeds.bookmark"))

    respond_to do |format|
      format.html { Magent.push("actors.judge", :on_view_bookmark, @bookmark.id) }
      format.json  { render :json => @bookmark.to_json(:except => %w[_keywords slug watchers]) }
      format.atom
    end
  end

  # GET /bookmarks/new
  # GET /bookmarks/new.xml
  def new
    @bookmark = Bookmark.new(params[:bookmark])
    respond_to do |format|
      format.html # new.html.erb
      format.json  { render :json => @bookmark.to_json }
    end
  end

  # GET /bookmarks/1/edit
  def edit
  end

  # POST /bookmarks
  # POST /bookmarks.xml
  def create
    @bookmark = Bookmark.new
    @bookmark.safe_update(%w[title body language tags wiki], params[:bookmark])
    @bookmark.group = current_group
    @bookmark.user = current_user

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
          @bookmark.user = @user
        end
      elsif !AppConfig.recaptcha["activate"]
        return create_draft!
      end
    end

    respond_to do |format|
      if (recaptcha_valid? || logged_in?) && @bookmark.user.valid? && @bookmark.save
        sweep_bookmark_views

        @bookmark.user.stats.add_bookmark_tags(*@bookmark.tags)
        current_group.tag_list.add_tags(*@bookmark.tags)

        @bookmark.user.on_activity(:ask_bookmark, current_group)
        current_group.on_activity(:ask_bookmark)

        Magent.push("actors.judge", :on_ask_bookmark, @bookmark.id)

        flash[:notice] = t(:flash_notice, :scope => "bookmarks.create")

        # TODO: move to magent
        users = User.find_experts(@bookmark.tags, [@bookmark.language],
                                                  :except => [@bookmark.user.id],
                                                  :group_id => current_group.id)
        followers = @bookmark.user.followers(:group_id => current_group.id, :languages => [@bookmark.language])

        (users - followers).each do |u|
          if !u.email.blank?
            Notifier.deliver_give_advice(u, current_group, @bookmark, false)
          end
        end

        followers.each do |u|
          if !u.email.blank?
            Notifier.deliver_give_advice(u, current_group, @bookmark, true)
          end
        end

        format.html { redirect_to(bookmark_path(@bookmark)) }
        format.json { render :json => @bookmark.to_json(:except => %w[_keywords watchers]), :status => :created}
      else
        @bookmark.errors.add(:captcha, "is invalid") unless recaptcha_valid?
        format.html { render :action => "new" }
        format.json { render :json => @bookmark.errors+@bookmark.user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /bookmarks/1
  # PUT /bookmarks/1.xml
  def update
    respond_to do |format|
      @bookmark.safe_update(%w[title body language tags wiki adult_content version_message], params[:bookmark])
      @bookmark.updated_by = current_user
      @bookmark.last_target = @bookmark

      @bookmark.slugs << @bookmark.slug
      @bookmark.send(:generate_slug)

      if @bookmark.valid? && @bookmark.save
        sweep_bookmark_views
        sweep_bookmark(@bookmark)

        flash[:notice] = t(:flash_notice, :scope => "bookmarks.update")
        format.html { redirect_to(bookmark_path(@bookmark)) }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.json  { render :json => @bookmark.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /bookmarks/1
  # DELETE /bookmarks/1.xml
  def destroy
    if @bookmark.user_id == current_user.id
      @bookmark.user.update_reputation(:delete_bookmark, current_group)
    end
    sweep_bookmark(@bookmark)
    sweep_bookmark_views
    @bookmark.destroy

    Magent.push("actors.judge", :on_destroy_bookmark, current_user.id, @bookmark.attributes)

    respond_to do |format|
      format.html { redirect_to(bookmarks_url) }
      format.json  { head :ok }
    end
  end

  def solve
    @answer = @bookmark.answers.find(params[:answer_id])
    @bookmark.answer = @answer
    @bookmark.accepted = true
    @bookmark.answered_with = @answer if @bookmark.answered_with.nil?

    respond_to do |format|
      if @bookmark.save
        sweep_bookmark(@bookmark)

        current_user.on_activity(:close_bookmark, current_group)
        if current_user != @answer.user
          @answer.user.update_reputation(:answer_picked_as_solution, current_group)
        end

        Magent.push("actors.judge", :on_bookmark_solved, @bookmark.id, @answer.id)

        flash[:notice] = t(:flash_notice, :scope => "bookmarks.solve")
        format.html { redirect_to bookmark_path(@bookmark) }
        format.json  { head :ok }
      else
        @tag_cloud = Bookmark.tag_cloud(:_id => @bookmark.id, :banned => false)
        options = {:per_page => 25, :page => params[:page] || 1,
                   :order => current_order, :banned => false}
        options[:_id] = {:$ne => @bookmark.answer_id} if @bookmark.answer_id
        @answers = @bookmark.answers.paginate(options)
        @answer = Answer.new

        format.html { render :action => "show" }
        format.json  { render :json => @bookmark.errors, :status => :unprocessable_entity }
      end
    end
  end

  def unsolve
    @answer_id = @bookmark.answer.id
    @answer_owner = @bookmark.answer.user

    @bookmark.answer = nil
    @bookmark.accepted = false
    @bookmark.answered_with = nil if @bookmark.answered_with == @bookmark.answer

    respond_to do |format|
      if @bookmark.save
        sweep_bookmark(@bookmark)

        flash[:notice] = t(:flash_notice, :scope => "bookmarks.unsolve")
        current_user.on_activity(:reopen_bookmark, current_group)
        if current_user != @answer_owner
          @answer_owner.update_reputation(:answer_unpicked_as_solution, current_group)
        end

        Magent.push("actors.judge", :on_bookmark_unsolved, @bookmark.id, @answer_id)

        format.html { redirect_to bookmark_path(@bookmark) }
        format.json  { head :ok }
      else
        @tag_cloud = Bookmark.tag_cloud(:_id => @bookmark.id, :banned => false)
        options = {:per_page => 25, :page => params[:page] || 1,
                   :order => current_order, :banned => false}
        options[:_id] = {:$ne => @bookmark.answer_id} if @bookmark.answer_id
        @answers = @bookmark.answers.paginate(options)
        @answer = Answer.new

        format.html { render :action => "show" }
        format.json  { render :json => @bookmark.errors, :status => :unprocessable_entity }
      end
    end
  end

  def close
    @bookmark = Bookmark.find_by_slug_or_id(params[:id])

    @bookmark.closed = true
    @bookmark.closed_at = Time.zone.now
    @bookmark.close_reason_id = params[:close_request_id]

    respond_to do |format|
      if @bookmark.save
        sweep_bookmark(@bookmark)

        format.html { redirect_to bookmark_path(@bookmark) }
        format.json { head :ok }
      else
        flash[:error] = @bookmark.errors.full_messages.join(", ")
        format.html { redirect_to bookmark_path(@bookmark) }
        format.json { render :json => @bookmark.errors, :status => :unprocessable_entity  }
      end
    end
  end

  def open
    @bookmark = Bookmark.find_by_slug_or_id(params[:id])

    @bookmark.closed = false
    @bookmark.close_reason_id = nil

    respond_to do |format|
      if @bookmark.save
        sweep_bookmark(@bookmark)

        format.html { redirect_to bookmark_path(@bookmark) }
        format.json { head :ok }
      else
        flash[:error] = @bookmark.errors.full_messages.join(", ")
        format.html { redirect_to bookmark_path(@bookmark) }
        format.json { render :json => @bookmark.errors, :status => :unprocessable_entity  }
      end
    end
  end

  def favorite
    @favorite = Favorite.new
    @favorite.bookmark = @bookmark
    @favorite.user = current_user
    @favorite.group = @bookmark.group

    @bookmark.add_watcher(current_user)

    if (@bookmark.user_id != current_user.id) && current_user.notification_opts.activities
      Notifier.deliver_favorited(current_user, @bookmark.group, @bookmark)
    end

    respond_to do |format|
      if @favorite.save
        @bookmark.add_favorite!(@favorite, current_user)
        flash[:notice] = t("favorites.create.success")
        format.html { redirect_to(bookmark_path(@bookmark)) }
        format.json { head :ok }
        format.js {
          render(:json => {:success => true,
                   :message => flash[:notice], :increment => 1 }.to_json)
        }
      else
        flash[:error] = @favorite.errors.full_messages.join("**")
        format.html { redirect_to(bookmark_path(@bookmark)) }
        format.js {
          render(:json => {:success => false,
                   :message => flash[:error], :increment => 0 }.to_json)
        }
        format.json { render :json => @favorite.errors, :status => :unprocessable_entity }
      end
    end
  end

  def unfavorite
    @favorite = current_user.favorite(@bookmark)
    if @favorite
      if current_user.can_modify?(@favorite)
        @bookmark.remove_favorite!(@favorite, current_user)
        @favorite.destroy
        @bookmark.remove_watcher(current_user)
      end
    end
    flash[:notice] = t("unfavorites.create.success")
    respond_to do |format|
      format.html { redirect_to(bookmark_path(@bookmark)) }
      format.js {
        render(:json => {:success => true,
                 :message => flash[:notice], :increment => -1 }.to_json)
      }
      format.json  { head :ok }
    end
  end

  def watch
    @bookmark = Bookmark.find_by_slug_or_id(params[:id])
    @bookmark.add_watcher(current_user)
    flash[:notice] = t("bookmarks.watch.success")
    respond_to do |format|
      format.html {redirect_to bookmark_path(@bookmark)}
      format.js {
        render(:json => {:success => true,
                 :message => flash[:notice] }.to_json)
      }
      format.json { head :ok }
    end
  end

  def unwatch
    @bookmark = Bookmark.find_by_slug_or_id(params[:id])
    @bookmark.remove_watcher(current_user)
    flash[:notice] = t("bookmarks.unwatch.success")
    respond_to do |format|
      format.html {redirect_to bookmark_path(@bookmark)}
      format.js {
        render(:json => {:success => true,
                 :message => flash[:notice] }.to_json)
      }
      format.json { head :ok }
    end
  end

  def move
    @bookmark = Bookmark.find_by_slug_or_id(params[:id])
    render
  end

  def move_to
    @group = Group.find_by_slug_or_id(params[:bookmark][:group])
    @bookmark = Bookmark.find_by_slug_or_id(params[:id])

    if @group
      @bookmark.group = @group

      if @bookmark.save
        sweep_bookmark(@bookmark)

        Answer.set({"bookmark_id" => @bookmark.id}, {"group_id" => @group.id})
      end
      flash[:notice] = t("bookmarks.move_to.success", :group => @group.name)
      redirect_to bookmark_path(@bookmark)
    else
      flash[:error] = t("bookmarks.move_to.group_dont_exists",
                        :group => params[:bookmark][:group])
      render :move
    end
  end

  def retag_to
    @bookmark = Bookmark.find_by_slug_or_id(params[:id])

    @bookmark.tags = params[:bookmark][:tags]
    @bookmark.updated_by = current_user
    @bookmark.last_target = @bookmark

    if @bookmark.save
      sweep_bookmark(@bookmark)

      if (Time.now - @bookmark.created_at) < 8.days
        @bookmark.on_activity(true)
      end

      Magent.push("actors.judge", :on_retag_bookmark, @bookmark.id, current_user.id)

      flash[:notice] = t("bookmarks.retag_to.success", :group => @bookmark.group.name)
      respond_to do |format|
        format.html {redirect_to bookmark_path(@bookmark)}
        format.js {
          render(:json => {:success => true,
                   :message => flash[:notice], :tags => @bookmark.tags }.to_json)
        }
      end
    else
      flash[:error] = t("bookmarks.retag_to.failure",
                        :group => params[:bookmark][:group])

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
    @bookmark = Bookmark.find_by_slug_or_id(params[:id])
    respond_to do |format|
      format.html {render}
      format.js {
        render(:json => {:success => true, :html => render_to_string(:partial => "bookmarks/retag_form",
                                                   :member  => @bookmark)}.to_json)
      }
    end
  end

  protected
  def check_permissions
    @bookmark = Bookmark.find_by_slug_or_id(params[:id])

    if @bookmark.nil?
      redirect_to bookmarks_path
    elsif !(current_user.can_modify?(@bookmark) ||
           (params[:action] != 'destroy' && @bookmark.can_be_deleted_by?(current_user)) ||
           current_user.owner_of?(@bookmark.group)) # FIXME: refactor
      flash[:error] = t("global.permission_denied")
      redirect_to bookmark_path(@bookmark)
    end
  end

  def check_update_permissions
    @bookmark = current_group.bookmarks.find_by_slug_or_id(params[:id])
    allow_update = true
    unless @bookmark.nil?
      if !current_user.can_modify?(@bookmark)
        if @bookmark.wiki
          if !current_user.can_edit_wiki_post_on?(@bookmark.group)
            allow_update = false
            reputation = @bookmark.group.reputation_constrains["edit_wiki_post"]
            flash[:error] = I18n.t("users.messages.errors.reputation_needed",
                                        :min_reputation => reputation,
                                        :action => I18n.t("users.actions.edit_wiki_post"))
          end
        else
          if !current_user.can_edit_others_posts_on?(@bookmark.group)
            allow_update = false
            reputation = @bookmark.group.reputation_constrains["edit_others_posts"]
            flash[:error] = I18n.t("users.messages.errors.reputation_needed",
                                        :min_reputation => reputation,
                                        :action => I18n.t("users.actions.edit_others_posts"))
          end
        end
        return redirect_to bookmark_path(@bookmark) if !allow_update
      end
    else
      return redirect_to bookmarks_path
    end
  end

  def check_favorite_permissions
    @bookmark = current_group.bookmarks.find_by_slug_or_id(params[:id])
    unless logged_in?
      flash[:error] = t(:unauthenticated, :scope => "favorites.create")
      respond_to do |format|
        format.html do
          flash[:error] += ", [#{t("global.please_login")}](#{new_user_session_path})"
          redirect_to bookmark_path(@bookmark)
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
    @bookmark = Bookmark.find_by_slug_or_id(params[:id])
    unless logged_in? && (current_user.can_retag_others_bookmarks_on?(current_group) ||  current_user.can_modify?(@bookmark))
      reputation = @bookmark.group.reputation_constrains["retag_others_bookmarks"]
      if !logged_in?
        flash[:error] = t("bookmarks.show.unauthenticated_retag")
      else
        flash[:error] = I18n.t("users.messages.errors.reputation_needed",
                               :min_reputation => reputation,
                               :action => I18n.t("users.actions.retag_others_bookmarks"))
      end
      respond_to do |format|
        format.html {redirect_to @bookmark}
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
    @bookmark = current_group.bookmarks.find_by_slug_or_id(params[:id])

    if @bookmark.nil?
      @bookmark = current_group.bookmarks.first(:slugs => params[:id], :select => [:_id, :slug])
      if @bookmark.present?
        head :moved_permanently, :location => bookmark_url(@bookmark)
        return
      elsif params[:id] =~ /^(\d+)/ && (@bookmark = current_group.bookmarks.first(:se_id => $1, :select => [:_id, :slug]))
        head :moved_permanently, :location => bookmark_url(@bookmark)
      else
        raise PageNotFound
      end
    end

    return if session[:age_confirmed] || is_bot? || !@bookmark.adult_content

    if !logged_in? || (Date.today.year.to_i - (current_user.birthday || Date.today).year.to_i) < 18
      render :template => "welcome/confirm_age"
    end
  end

  def create_draft!
    draft = Draft.create!(:bookmark => @bookmark)
    session[:draft] = draft.id
    login_required
  end
end
