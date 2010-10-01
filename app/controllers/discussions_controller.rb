class DiscussionsController < ApplicationController
  before_filter :login_required, :except => [:new, :create, :index, :show, :tags, :unanswered, :related_discussions, :tags_for_autocomplete, :retag, :retag_to]
  before_filter :admin_required, :only => [:move, :move_to]
  before_filter :moderator_required, :only => [:close]
  before_filter :check_permissions, :only => [:solve, :unsolve, :destroy]
  before_filter :check_update_permissions, :only => [:edit, :update, :revert]
  before_filter :check_favorite_permissions, :only => [:favorite, :unfavorite] #TODO remove this
  before_filter :set_active_tag
  before_filter :check_age, :only => [:show]
  before_filter :check_retag_permissions, :only => [:retag, :retag_to]

  tabs :default => :discussions, :tags => :tags,
       :unanswered => :unanswered, :new => :contribute

  subtabs :index => [[:newest, "created_at desc"], [:hot, "hotness desc, views_count desc"], [:votes, "votes_average desc"], [:activity, "activity_at desc"], [:expert, "created_at desc"]],
          :unanswered => [[:newest, "created_at desc"], [:votes, "votes_average desc"], [:mytags, "created_at desc"]],
          :show => [[:votes, "votes_average desc"], [:oldest, "created_at asc"], [:newest, "created_at desc"]]
  helper :votes
  helper :channels

  # GET /discussions
  # GET /discussions.xml
  def index
    if params[:language] || request.query_string =~ /tags=/
      params.delete(:language)
      head :moved_permanently, :location => url_for(params)
      return
    end

    set_page_title(t("discussions.index.title"))
    conditions = scoped_conditions(:banned => false)

    if params[:sort] == "hot"
      conditions[:activity_at] = {"$gt" => 5.days.ago}
    end

    @discussions = Discussion.paginate({:per_page => 25, :page => params[:page] || 1,
                                   :order => current_order,
                                   :fields => (Discussion.keys.keys - ["_keywords", "watchers"])}.
                                               merge(conditions))

    @langs_conds = scoped_conditions[:language][:$in]

    if logged_in?
      feed_params = { :feed_token => current_user.feed_token }
    else
      feed_params = {  :lang => I18n.locale,
                          :mylangs => current_languages }
    end
    add_feeds_url(url_for({:format => "atom"}.merge(feed_params)), t("feeds.discussions"))
    if params[:tags]
      add_feeds_url(url_for({:format => "atom", :tags => params[:tags]}.merge(feed_params)),
                    "#{t("feeds.tag")} #{params[:tags].inspect}")
    end
    @tag_cloud = Discussion.tag_cloud(scoped_conditions, 25)

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render :json => @discussions.to_json(:except => %w[_keywords watchers slugs]) }
      format.atom
    end
  end


  def history
    @discussion = current_group.discussions.find_by_slug_or_id(params[:id])

    respond_to do |format|
      format.html
      format.json { render :json => @discussion.versions.to_json }
    end
  end

  def diff
    @discussion = current_group.discussions.find_by_slug_or_id(params[:id])
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
    @discussion.load_version(params[:version].to_i)

    respond_to do |format|
      format.html
    end
  end

  def related_discussions
    if params[:id]
      @discussion = Discussion.find(params[:id])
    elsif params[:discussion]
      @discussion = Discussion.new(params[:discussion])
      @discussion.group_id = current_group.id
    end

    @discussion.tags += @discussion.title.downcase.split(",").join(" ").split(" ")

    @discussions = Discussion.related_discussions(@discussion, :page => params[:page],
                                                       :per_page => params[:per_page],
                                                       :order => "answers_count desc")

    respond_to do |format|
      format.js do
        render :json => {:html => render_to_string(:partial => "discussions/discussion",
                                                   :collection  => @discussions,
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

    set_page_title(t("discussions.unanswered.title"))
    conditions = scoped_conditions({:answered_with_id => nil, :banned => false, :closed => false})

    if logged_in?
      if @active_subtab.to_s == "expert"
        @current_tags = current_user.stats(:expert_tags).expert_tags
      elsif @active_subtab.to_s == "mytags"
        @current_tags = current_user.preferred_tags_on(current_group)
      end
    end

    @tag_cloud = Discussion.tag_cloud(conditions, 25)

    @discussions = Discussion.paginate({:order => current_order,
                                    :per_page => 25,
                                    :page => params[:page] || 1,
                                    :fields => (Discussion.keys.keys - ["_keywords", "watchers"])
                                   }.merge(conditions))

    respond_to do |format|
      format.html # unanswered.html.erb
      format.json  { render :json => @discussions.to_json(:except => %w[_keywords slug watchers]) }
    end
  end

  def tags
    conditions = scoped_conditions({:answered_with_id => nil, :banned => false})
    if params[:q].blank?
      @tag_cloud = Discussion.tag_cloud(conditions)
    else
      @tag_cloud = Discussion.find_tags(/^#{Regexp.escape(params[:q])}/, conditions)
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
          result = Discussion.find_tags(/^#{Regexp.escape(q.downcase)}/i,
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

  # GET /discussions/1
  # GET /discussions/1.xml
  def show
    if params[:language]
      params.delete(:language)
      head :moved_permanently, :location => url_for(params)
      return
    end

    @tag_cloud = Discussion.tag_cloud(:_id => @discussion.id, :banned => false)
    options = {:per_page => 25, :page => params[:page] || 1,
               :order => current_order, :banned => false}
    options[:_id] = {:$ne => @discussion.answer_id} if @discussion.answer_id
    @answers = @discussion.answers.paginate(options)

    @answer = Answer.new(params[:answer])

    if @discussion.user != current_user && !is_bot?
      @discussion.viewed!(request.remote_ip)

      if (@discussion.views_count % 10) == 0
        sweep_discussion(@discussion)
      end
    end

    set_page_title(@discussion.title)
    add_feeds_url(url_for(:format => "atom"), t("feeds.discussion"))

    respond_to do |format|
      format.html { Magent.push("actors.judge", :on_view_discussion, @discussion.id) }
      format.json  { render :json => @discussion.to_json(:except => %w[_keywords slug watchers]) }
      format.atom
    end
  end

  # GET /discussions/new
  # GET /discussions/new.xml
  def new
    @discussion = Discussion.new(params[:discussion])
    respond_to do |format|
      format.html # new.html.erb
      format.json  { render :json => @discussion.to_json }
    end
  end

  # GET /discussions/1/edit
  def edit
  end

  # POST /discussions
  # POST /discussions.xml
  def create
    @discussion = Discussion.new
    @discussion.safe_update(%w[title body language tags wiki], params[:discussion])
    @discussion.group = current_group
    @discussion.user = current_user

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
          @discussion.user = @user
        end
      elsif !AppConfig.recaptcha["activate"]
        return create_draft!
      end
    end

    respond_to do |format|
      if (recaptcha_valid? || logged_in?) && @discussion.user.valid? && @discussion.save
        sweep_discussion_views

        @discussion.user.stats.add_discussion_tags(*@discussion.tags)
        current_group.tag_list.add_tags(*@discussion.tags)

        @discussion.user.on_activity(:ask_discussion, current_group)
        current_group.on_activity(:ask_discussion)

        Magent.push("actors.judge", :on_ask_discussion, @discussion.id)

        flash[:notice] = t(:flash_notice, :scope => "discussions.create")

        # TODO: move to magent
        users = User.find_experts(@discussion.tags, [@discussion.language],
                                                  :except => [@discussion.user.id],
                                                  :group_id => current_group.id)
        followers = @discussion.user.followers(:group_id => current_group.id, :languages => [@discussion.language])

        (users - followers).each do |u|
          if !u.email.blank?
            Notifier.deliver_give_advice(u, current_group, @discussion, false)
          end
        end

        followers.each do |u|
          if !u.email.blank?
            Notifier.deliver_give_advice(u, current_group, @discussion, true)
          end
        end

        format.html { redirect_to(discussion_path(@discussion)) }
        format.json { render :json => @discussion.to_json(:except => %w[_keywords watchers]), :status => :created}
      else
        @discussion.errors.add(:captcha, "is invalid") unless recaptcha_valid?
        format.html { render :action => "new" }
        format.json { render :json => @discussion.errors+@discussion.user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /discussions/1
  # PUT /discussions/1.xml
  def update
    respond_to do |format|
      @discussion.safe_update(%w[title body language tags wiki adult_content version_message], params[:discussion])
      @discussion.updated_by = current_user
      @discussion.last_target = @discussion

      @discussion.slugs << @discussion.slug
      @discussion.send(:generate_slug)

      if @discussion.valid? && @discussion.save
        sweep_discussion_views
        sweep_discussion(@discussion)

        flash[:notice] = t(:flash_notice, :scope => "discussions.update")
        format.html { redirect_to(discussion_path(@discussion)) }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.json  { render :json => @discussion.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /discussions/1
  # DELETE /discussions/1.xml
  def destroy
    if @discussion.user_id == current_user.id
      @discussion.user.update_reputation(:delete_discussion, current_group)
    end
    sweep_discussion(@discussion)
    sweep_discussion_views
    @discussion.destroy

    Magent.push("actors.judge", :on_destroy_discussion, current_user.id, @discussion.attributes)

    respond_to do |format|
      format.html { redirect_to(discussions_url) }
      format.json  { head :ok }
    end
  end

  def solve
    @answer = @discussion.answers.find(params[:answer_id])
    @discussion.answer = @answer
    @discussion.accepted = true
    @discussion.answered_with = @answer if @discussion.answered_with.nil?

    respond_to do |format|
      if @discussion.save
        sweep_discussion(@discussion)

        current_user.on_activity(:close_discussion, current_group)
        if current_user != @answer.user
          @answer.user.update_reputation(:answer_picked_as_solution, current_group)
        end

        Magent.push("actors.judge", :on_discussion_solved, @discussion.id, @answer.id)

        flash[:notice] = t(:flash_notice, :scope => "discussions.solve")
        format.html { redirect_to discussion_path(@discussion) }
        format.json  { head :ok }
      else
        @tag_cloud = Discussion.tag_cloud(:_id => @discussion.id, :banned => false)
        options = {:per_page => 25, :page => params[:page] || 1,
                   :order => current_order, :banned => false}
        options[:_id] = {:$ne => @discussion.answer_id} if @discussion.answer_id
        @answers = @discussion.answers.paginate(options)
        @answer = Answer.new

        format.html { render :action => "show" }
        format.json  { render :json => @discussion.errors, :status => :unprocessable_entity }
      end
    end
  end

  def unsolve
    @answer_id = @discussion.answer.id
    @answer_owner = @discussion.answer.user

    @discussion.answer = nil
    @discussion.accepted = false
    @discussion.answered_with = nil if @discussion.answered_with == @discussion.answer

    respond_to do |format|
      if @discussion.save
        sweep_discussion(@discussion)

        flash[:notice] = t(:flash_notice, :scope => "discussions.unsolve")
        current_user.on_activity(:reopen_discussion, current_group)
        if current_user != @answer_owner
          @answer_owner.update_reputation(:answer_unpicked_as_solution, current_group)
        end

        Magent.push("actors.judge", :on_discussion_unsolved, @discussion.id, @answer_id)

        format.html { redirect_to discussion_path(@discussion) }
        format.json  { head :ok }
      else
        @tag_cloud = Discussion.tag_cloud(:_id => @discussion.id, :banned => false)
        options = {:per_page => 25, :page => params[:page] || 1,
                   :order => current_order, :banned => false}
        options[:_id] = {:$ne => @discussion.answer_id} if @discussion.answer_id
        @answers = @discussion.answers.paginate(options)
        @answer = Answer.new

        format.html { render :action => "show" }
        format.json  { render :json => @discussion.errors, :status => :unprocessable_entity }
      end
    end
  end

  def close
    @discussion = Discussion.find_by_slug_or_id(params[:id])

    @discussion.closed = true
    @discussion.closed_at = Time.zone.now
    @discussion.close_reason_id = params[:close_request_id]

    respond_to do |format|
      if @discussion.save
        sweep_discussion(@discussion)

        format.html { redirect_to discussion_path(@discussion) }
        format.json { head :ok }
      else
        flash[:error] = @discussion.errors.full_messages.join(", ")
        format.html { redirect_to discussion_path(@discussion) }
        format.json { render :json => @discussion.errors, :status => :unprocessable_entity  }
      end
    end
  end

  def open
    @discussion = Discussion.find_by_slug_or_id(params[:id])

    @discussion.closed = false
    @discussion.close_reason_id = nil

    respond_to do |format|
      if @discussion.save
        sweep_discussion(@discussion)

        format.html { redirect_to discussion_path(@discussion) }
        format.json { head :ok }
      else
        flash[:error] = @discussion.errors.full_messages.join(", ")
        format.html { redirect_to discussion_path(@discussion) }
        format.json { render :json => @discussion.errors, :status => :unprocessable_entity  }
      end
    end
  end

  def favorite
    @favorite = Favorite.new
    @favorite.discussion = @discussion
    @favorite.user = current_user
    @favorite.group = @discussion.group

    @discussion.add_watcher(current_user)

    if (@discussion.user_id != current_user.id) && current_user.notification_opts.activities
      Notifier.deliver_favorited(current_user, @discussion.group, @discussion)
    end

    respond_to do |format|
      if @favorite.save
        @discussion.add_favorite!(@favorite, current_user)
        flash[:notice] = t("favorites.create.success")
        format.html { redirect_to(discussion_path(@discussion)) }
        format.json { head :ok }
        format.js {
          render(:json => {:success => true,
                   :message => flash[:notice], :increment => 1 }.to_json)
        }
      else
        flash[:error] = @favorite.errors.full_messages.join("**")
        format.html { redirect_to(discussion_path(@discussion)) }
        format.js {
          render(:json => {:success => false,
                   :message => flash[:error], :increment => 0 }.to_json)
        }
        format.json { render :json => @favorite.errors, :status => :unprocessable_entity }
      end
    end
  end

  def unfavorite
    @favorite = current_user.favorite(@discussion)
    if @favorite
      if current_user.can_modify?(@favorite)
        @discussion.remove_favorite!(@favorite, current_user)
        @favorite.destroy
        @discussion.remove_watcher(current_user)
      end
    end
    flash[:notice] = t("unfavorites.create.success")
    respond_to do |format|
      format.html { redirect_to(discussion_path(@discussion)) }
      format.js {
        render(:json => {:success => true,
                 :message => flash[:notice], :increment => -1 }.to_json)
      }
      format.json  { head :ok }
    end
  end

  def watch
    @discussion = Discussion.find_by_slug_or_id(params[:id])
    @discussion.add_watcher(current_user)
    flash[:notice] = t("discussions.watch.success")
    respond_to do |format|
      format.html {redirect_to discussion_path(@discussion)}
      format.js {
        render(:json => {:success => true,
                 :message => flash[:notice] }.to_json)
      }
      format.json { head :ok }
    end
  end

  def unwatch
    @discussion = Discussion.find_by_slug_or_id(params[:id])
    @discussion.remove_watcher(current_user)
    flash[:notice] = t("discussions.unwatch.success")
    respond_to do |format|
      format.html {redirect_to discussion_path(@discussion)}
      format.js {
        render(:json => {:success => true,
                 :message => flash[:notice] }.to_json)
      }
      format.json { head :ok }
    end
  end

  def move
    @discussion = Discussion.find_by_slug_or_id(params[:id])
    render
  end

  def move_to
    @group = Group.find_by_slug_or_id(params[:discussion][:group])
    @discussion = Discussion.find_by_slug_or_id(params[:id])

    if @group
      @discussion.group = @group

      if @discussion.save
        sweep_discussion(@discussion)

        Answer.set({"discussion_id" => @discussion.id}, {"group_id" => @group.id})
      end
      flash[:notice] = t("discussions.move_to.success", :group => @group.name)
      redirect_to discussion_path(@discussion)
    else
      flash[:error] = t("discussions.move_to.group_dont_exists",
                        :group => params[:discussion][:group])
      render :move
    end
  end

  def retag_to
    @discussion = Discussion.find_by_slug_or_id(params[:id])

    @discussion.tags = params[:discussion][:tags]
    @discussion.updated_by = current_user
    @discussion.last_target = @discussion

    if @discussion.save
      sweep_discussion(@discussion)

      if (Time.now - @discussion.created_at) < 8.days
        @discussion.on_activity(true)
      end

      Magent.push("actors.judge", :on_retag_discussion, @discussion.id, current_user.id)

      flash[:notice] = t("discussions.retag_to.success", :group => @discussion.group.name)
      respond_to do |format|
        format.html {redirect_to discussion_path(@discussion)}
        format.js {
          render(:json => {:success => true,
                   :message => flash[:notice], :tags => @discussion.tags }.to_json)
        }
      end
    else
      flash[:error] = t("discussions.retag_to.failure",
                        :group => params[:discussion][:group])

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
    @discussion = Discussion.find_by_slug_or_id(params[:id])
    respond_to do |format|
      format.html {render}
      format.js {
        render(:json => {:success => true, :html => render_to_string(:partial => "discussions/retag_form",
                                                   :member  => @discussion)}.to_json)
      }
    end
  end

  protected
  def check_permissions
    @discussion = Discussion.find_by_slug_or_id(params[:id])

    if @discussion.nil?
      redirect_to discussions_path
    elsif !(current_user.can_modify?(@discussion) ||
           (params[:action] != 'destroy' && @discussion.can_be_deleted_by?(current_user)) ||
           current_user.owner_of?(@discussion.group)) # FIXME: refactor
      flash[:error] = t("global.permission_denied")
      redirect_to discussion_path(@discussion)
    end
  end

  def check_update_permissions
    @discussion = current_group.discussions.find_by_slug_or_id(params[:id])
    allow_update = true
    unless @discussion.nil?
      if !current_user.can_modify?(@discussion)
        if @discussion.wiki
          if !current_user.can_edit_wiki_post_on?(@discussion.group)
            allow_update = false
            reputation = @discussion.group.reputation_constrains["edit_wiki_post"]
            flash[:error] = I18n.t("users.messages.errors.reputation_needed",
                                        :min_reputation => reputation,
                                        :action => I18n.t("users.actions.edit_wiki_post"))
          end
        else
          if !current_user.can_edit_others_posts_on?(@discussion.group)
            allow_update = false
            reputation = @discussion.group.reputation_constrains["edit_others_posts"]
            flash[:error] = I18n.t("users.messages.errors.reputation_needed",
                                        :min_reputation => reputation,
                                        :action => I18n.t("users.actions.edit_others_posts"))
          end
        end
        return redirect_to discussion_path(@discussion) if !allow_update
      end
    else
      return redirect_to discussions_path
    end
  end

  def check_favorite_permissions
    @discussion = current_group.discussions.find_by_slug_or_id(params[:id])
    unless logged_in?
      flash[:error] = t(:unauthenticated, :scope => "favorites.create")
      respond_to do |format|
        format.html do
          flash[:error] += ", [#{t("global.please_login")}](#{new_user_session_path})"
          redirect_to discussion_path(@discussion)
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
    @discussion = Discussion.find_by_slug_or_id(params[:id])
    unless logged_in? && (current_user.can_retag_others_discussions_on?(current_group) ||  current_user.can_modify?(@discussion))
      reputation = @discussion.group.reputation_constrains["retag_others_discussions"]
      if !logged_in?
        flash[:error] = t("discussions.show.unauthenticated_retag")
      else
        flash[:error] = I18n.t("users.messages.errors.reputation_needed",
                               :min_reputation => reputation,
                               :action => I18n.t("users.actions.retag_others_discussions"))
      end
      respond_to do |format|
        format.html {redirect_to @discussion}
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
    @discussion = current_group.discussions.find_by_slug_or_id(params[:id])

    if @discussion.nil?
      @discussion = current_group.discussions.first(:slugs => params[:id], :select => [:_id, :slug])
      if @discussion.present?
        head :moved_permanently, :location => discussion_url(@discussion)
        return
      elsif params[:id] =~ /^(\d+)/ && (@discussion = current_group.discussions.first(:se_id => $1, :select => [:_id, :slug]))
        head :moved_permanently, :location => discussion_url(@discussion)
      else
        raise PageNotFound
      end
    end

    return if session[:age_confirmed] || is_bot? || !@discussion.adult_content

    if !logged_in? || (Date.today.year.to_i - (current_user.birthday || Date.today).year.to_i) < 18
      render :template => "welcome/confirm_age"
    end
  end

  def create_draft!
    draft = Draft.create!(:discussion => @discussion)
    session[:draft] = draft.id
    login_required
  end
end
