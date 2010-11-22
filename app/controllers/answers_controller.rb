class AnswersController < ApplicationController
  before_filter :login_required, :except => [:show, :create]
  before_filter :check_permissions, :only => [:destroy]
  before_filter :check_update_permissions, :only => [:edit, :update, :revert]

  helper :votes

  def history
    @answer = Answer.find(params[:id])
    @item = @answer.item

    respond_to do |format|
      format.html
      format.json { render :json => @answer.versions.to_json }
    end
  end

  def diff
    @answer = Answer.find(params[:id])
    @item = @answer.item
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
    @item = @answer.item
    @answer.load_version(params[:version].to_i)

    respond_to do |format|
      format.html
    end
  end

  def show
    @answer = Answer.find(params[:id])
    raise PageNotFound if @answer.nil?
    @item = @answer.item
    respond_to do |format|
      format.html
      format.json  { render :json => @answer.to_json }
    end
  end

  def create
    @answer = Answer.new
    @answer.safe_update(%w[body wiki anonymous mode], params[:answer])

    mode = params[:answer]
    moded = mode[:mode]

    if moded == "item"
     @item = Item.find_by_slug_or_id(params[:item_id])
     @answer.item = @item
     @answer.group_id = @item.group_id
     puts "create item answer"
    end

    if moded == "discussion"
     @discussion = Discussion.find_by_slug_or_id(params[:discussion_id])
     @answer.discussion = @discussion
     @answer.group_id = @discussion.group_id
     puts "create discussion answer"
    end



    # workaround, seems like mm default values are broken
    @answer.votes_count = 0
    @answer.votes_average = 0
    @answer.flags_count = 0

    @answer.user = current_user
    if !logged_in?
      if recaptcha_valid? && params[:user]
        @user = User.first(:email => params[:user][:email])
        if @user.present?
          if !@user.anonymous
            flash[:notice] = "The user is already registered, please log in"
            return create_draft!
          else
            @answer.user = @user
          end
        else
          @user = User.new(:anonymous => true, :login => "Anonymous")
          @user.safe_update(%w[name email website], params[:user])
          @user.login = @user.name if @user.name.present?
          @user.save!
          @answer.user = @user
        end
      elsif !AppConfig.recaptcha["activate"]
        return create_draft!
      end
    end

    respond_to do |format|

      if moded == "item"
      if (logged_in? || (recaptcha_valid? && @answer.user.valid?)) && @answer.save
        after_create_item_answer

        flash[:notice] = t(:flash_notice, :scope => "answers.create")
        #format.html{redirect_to item_path(@item)}

        format.html { redirect_to("/#{@item.section}/#{@item.slug}") }

        format.json { render :json => @answer.to_json(:except => %w[_keywords]) }
        format.js do
          render(:json => {:success => true, :message => flash[:notice],
            :html => render_to_string(:partial => "items/answer",
                                      :object => @answer,
                                      :locals => {:item => @item})}.to_json)
        end
      else
        @answer.errors.add(:captcha, "is invalid") if !logged_in? && !recaptcha_valid?

        errors = @answer.errors
        errors.merge!(@answer.user.errors) if @answer.user.anonymous && !@answer.user.valid?
        puts errors.full_messages

        flash.now[:error] = errors.full_messages
        format.html{redirect_to item_path(@item)}
        format.json { render :json => errors, :status => :unprocessable_entity }
        format.js {render :json => {:success => false, :message => flash.now[:error] }.to_json }
      end
      end #end item mode

     if moded == "discussion"
      if (logged_in? || (recaptcha_valid? && @answer.user.valid?)) && @answer.save
        after_create_discussion_answer

        flash[:notice] = t(:flash_notice, :scope => "answers.create")
        format.html{redirect_to discussion_path(@discussion)}
        format.json { render :json => @answer.to_json(:except => %w[_keywords]) }
        format.js do
          render(:json => {:success => true, :message => flash[:notice],
            :html => render_to_string(:partial => "discussion/answer",
                                      :object => @answer,
                                      :locals => {:discussion => @discussion})}.to_json)
        end
      else
        @answer.errors.add(:captcha, "is invalid") if !logged_in? && !recaptcha_valid?

        errors = @answer.errors
        errors.merge!(@answer.user.errors) if @answer.user.anonymous && !@answer.user.valid?
        puts errors.full_messages

        flash.now[:error] = errors.full_messages
        format.html{redirect_to discussion_path(@discussion)}
        format.json { render :json => errors, :status => :unprocessable_entity }
        format.js {render :json => {:success => false, :message => flash.now[:error] }.to_json }
      end
      end #end discussion mode

    end #end do format

  end #end create

  def edit
    @item = @answer.item
  end

  def update
    respond_to do |format|
      @item = @answer.item
      @answer.safe_update(%w[body wiki version_message anonymous], params[:answer])
      @answer.updated_by = current_user

      if @answer.valid? && @answer.save
        sweep_item(@item)

        Item.update_last_target(@item.id, @answer)

        flash[:notice] = t(:flash_notice, :scope => "answers.update")

        Magent.push("actors.judge", :on_update_answer, @answer.id)

        if @item.mode == "news_article"
          format.html { redirect_to(news_article_path(@item)) }        
        else
          format.html { redirect_to("/#{@item.section}/#{@item.slug}") }
        end


        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @answer.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @item = @answer.item
    if @answer.user_id == current_user.id
      @answer.user.update_reputation(:delete_answer, current_group)
    end
    @answer.destroy
    @item.answer_removed!
    sweep_item(@item)

    Magent.push("actors.judge", :on_destroy_answer, current_user.id, @answer.attributes)

    respond_to do |format|
      format.html { redirect_to("/#{@item.section}/#{@item.slug}") }
      format.json { head :ok }
    end
  end

  protected
  def check_permissions
    @answer = Answer.find(params[:id])
    if !@answer.nil?
      unless (current_user.can_modify?(@answer) || current_user.mod_of?(@answer.group))
        flash[:error] = t("global.permission_denied")
        redirect_to item_path(@answer.item)
      end
    else
      redirect_to items_path
    end
  end

  def check_update_permissions
    @answer = Answer.find!(params[:id])

    allow_update = true
    unless @answer.nil?
      if !current_user.can_modify?(@answer)
        if @answer.wiki
          if !current_user.can_edit_wiki_post_on?(@answer.group)
            allow_update = false
            reputation = @item.group.reputation_constrains["edit_wiki_post"]
            flash[:error] = I18n.t("users.messages.errors.reputation_needed",
                                        :min_reputation => reputation,
                                        :action => I18n.t("users.actions.edit_wiki_post"))
          end
        else
          if !current_user.can_edit_others_posts_on?(@answer.group)
            allow_update = false
            reputation = @answer.group.reputation_constrains["edit_others_posts"]
            flash[:error] = I18n.t("users.messages.errors.reputation_needed",
                                        :min_reputation => reputation,
                                        :action => I18n.t("users.actions.edit_others_posts"))
          end
        end
        return redirect_to item_path(@answer.item) if !allow_update
      end
    else
      return redirect_to items_path
    end
  end

  def create_draft!
    draft = Draft.create(:answer => @answer)
    session[:draft] = draft.id
    login_required
  end

  # TODO: use magent to do it
  def after_create_item_answer
    sweep_item(@item)

    Item.update_last_target(@item.id, @answer)

    @item.answer_added!
    current_group.on_activity(:answer_item)

    unless @answer.anonymous
      @answer.user.stats.add_answer_tags(*@item.tags)
      @answer.user.on_activity(:answer_item, current_group)

      search_opts = {"notification_opts.#{current_group.id}.new_answer" => {:$in => ["1", true]},
                      :_id => {:$ne => @answer.user.id},
                      :select => ["email"]}

      users = User.all(search_opts.merge(:_id => @item.watchers))
      users.push(@item.user) if !@item.user.nil? && @item.user != @answer.user
      followers = @answer.user.followers(:languages => [@item.language], :group_id => current_group.id)

      users ||= []
      followers ||= []
      (users - followers).each do |u|
        if !u.email.blank? && u.notification_opts.new_answer
          Notifier.deliver_new_answer(u, current_group, @answer, false)
        end
      end

      followers.each do |u|
        if !u.email.blank? && u.notification_opts.new_answer
          Notifier.deliver_new_answer(u, current_group, @answer, true)
        end
      end
    end
  end

 # TODO: use magent to do it
  def after_create_discussion_answer
    sweep_discussion(@discussion)

    Discussion.update_last_target(@discussion.id, @answer)

    @discussion.answer_added!
    current_group.on_activity(:answer_discussion)

    unless @answer.anonymous
      @answer.user.stats.add_answer_tags(*@discussion.tags)
      @answer.user.on_activity(:answer_discussion, current_group)

      search_opts = {"notification_opts.#{current_group.id}.new_answer" => {:$in => ["1", true]},
                      :_id => {:$ne => @answer.user.id},
                      :select => ["email"]}

      users = User.all(search_opts.merge(:_id => @discussion.watchers))
      users.push(@discussion.user) if !@discussion.user.nil? && @discussion.user != @answer.user
      followers = @answer.user.followers(:languages => [@discussion.language], :group_id => current_group.id)

      users ||= []
      followers ||= []
      (users - followers).each do |u|
        if !u.email.blank? && u.notification_opts.new_answer
          Notifier.deliver_new_answer(u, current_group, @answer, false)
        end
      end

      followers.each do |u|
        if !u.email.blank? && u.notification_opts.new_answer
          Notifier.deliver_new_answer(u, current_group, @answer, true)
        end
      end
    end
  end


end
