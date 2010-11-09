class ShowItemsController < ApplicationController
  before_filter :login_required, :except => [:new, :create, :index, :show, :tags, :unanswered, :related_items, :tags_for_autocomplete, :retag, :retag_to]
  before_filter :admin_required, :only => [:move, :move_to]
  before_filter :moderator_required, :only => [:close]
  before_filter :check_permissions, :only => [:solve, :unsolve, :destroy]
  before_filter :check_update_permissions, :only => [:edit, :update, :revert]
  before_filter :check_favorite_permissions, :only => [:favorite, :unfavorite] #TODO remove this
  before_filter :set_active_tag
  before_filter :set_active_section
  before_filter :check_mode
  before_filter :check_age, :only => [:show]
  before_filter :check_retag_permissions, :only => [:retag, :retag_to]

  tabs :default => @mode, :tags => :tags,
       :unanswered => :unanswered, :new => :ask_item

  subtabs :index => [[:newest, "created_at desc"], [:hot, "hotness desc, views_count desc"], [:votes, "votes_average desc"], [:activity, "activity_at desc"], [:expert, "created_at desc"]],
          :unanswered => [[:newest, "created_at desc"], [:votes, "votes_average desc"], [:mytags, "created_at desc"]],
          :show => [[:votes, "votes_average desc"], [:oldest, "created_at asc"], [:newest, "created_at desc"]]

  helper :votes
  helper :channels
  helper :items


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
      #format.html { Magent.push("actors.judge", :on_view_item, @item.id) }

        if @item.mode == "something"
          format.html { redirect_to(news_article_path(@item)) }        
        else
          format.html 
        end


      format.json  { render :json => @item.to_json(:except => %w[_keywords slug watchers]) }
      format.atom
    end
  end




  protected

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

  def set_active_tag
    @active_tag = "tag_#{params[:tags]}" if params[:tags]
    @active_tag
  end

  def set_active_section
    @section = params[:section]
    @section
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
