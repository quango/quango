class ImagesController < ApplicationController
  before_filter :login_required
  before_filter :find_scope
  #before_filter :check_permissions, :except => [:create]

  def create
    @image = Image.new
    @image.body = params[:body]
    @image.mode = params[:mode]
    @image.item_id = params[:source]
    @image.parent = params[:source]
    #@image.Commentable = scope
    @image.user = current_user
    @image.group = current_group

    if saved = @image.save
      current_user.on_activity(:Image_item, current_group)
      Magent.push("actors.judge", :on_Image, @image.id)

      if item_id = @image.item_id
        Item.update_last_target(item_id, @image)
      end

      if discussion_id = @image.discussion_id
        Discussion.update_last_target(discussion_id, @image)
      end

      flash[:notice] = t("Images.create.flash_notice")
    else
      flash[:error] = @image.errors.full_messages.join(", ")
    end

    # TODO: use magent to do it, temporarily disabled
    if (item = @image.find_item) && (recipient = @image.find_recipient)
      email = recipient.email
      if !email.blank? && current_user.id != recipient.id && recipient.notification_opts.new_answer
        #Notifier.deliver_new_Image(current_group, @image, recipient, item)
      end
    end

    respond_to do |format|
      if saved

        if @image.mode == "news"
          format.html { redirect_to(newsfeed_path(@item)) }        
        elsif @image.mode == "video"
          format.html { redirect_to(video_path(@item)) }        
        elsif @image.mode == "article"
          format.html { redirect_to(article_path(@item)) }  
        elsif @image.mode == "blog"
          format.html { redirect_to(blog_path(@item)) }  
        elsif @image.mode == "question"
          format.html { redirect_to(question_path(@item)) }  
        elsif @image.mode == "discussion"
          format.html { redirect_to(discussion_path(@item)) }  
        elsif @image.mode == "bookmark"
          format.html { redirect_to(bookmark_path(@item)) }  
        else
          format.html { redirect_to(item_path(@item)) }
        end


        format.html {redirect_to params[:source]}
        format.json {render :json => @image.to_json, :status => :created}
        format.js do
          render(:json => {:success => true, :message => flash[:notice],
            :html => render_to_string(:partial => "Images/Image",
                                      :object => @image,
                                      :locals => {:source => params[:source], :mini => true})}.to_json)
        end
      else
        format.html {redirect_to params[:source]}
        format.json {render :json => @image.errors.to_json, :status => :unprocessable_entity }
        format.js {render :json => {:success => false, :message => flash[:error] }.to_json }
      end
    end
  end

  def edit
    @image = current_scope.find(params[:id])
    respond_to do |format|
      format.html
      format.js do
        render :json => {:status => :ok,
         :html => render_to_string(:partial => "Images/edit_form",
                                   :locals => {:source => params[:source],
                                               :Commentable => @image.Commentable})
        }
      end
    end
  end

  def update
    respond_to do |format|
      @image = Image.find(params[:id])
      @image.body = params[:body]
      @image.title = params[:title]
      if @image.valid? && @image.save
        if item_id = @image.item_id
          Item.update_last_target(item_id, @image)
        end

        flash[:notice] = t(:flash_notice, :scope => "Images.update")
        format.html { redirect_to(params[:source]) }
        format.json { render :json => @image.to_json, :status => :ok}
        format.js { render :json => { :message => flash[:notice],
                                      :success => true,
                                      :body => @image.body} }
      else
        flash[:error] = @image.errors.full_messages.join(", ")
        format.html { render :action => "edit" }
        format.json { render :json => @image.errors, :status => :unprocessable_entity }
        format.js { render :json => { :success => false, :message => flash[:error]}.to_json }
      end
    end
  end

  def destroy
    @image = scope.Images.find(params[:id])
    @image.destroy

    respond_to do |format|
      format.html { redirect_to(params[:source] << "dastrey") }
      format.json { head :ok }
    end
  end

  protected
  def check_permissions
    @image = current_scope.find(params[:id])
    valid = false
    if params[:action] == "destroy"
      valid = @image.can_be_deleted_by?(current_user)
    else
      valid = current_user.can_modify?(@image) || current_user.mod_of?(@image.group)
    end

    if !valid
      respond_to do |format|
        format.html do
          flash[:error] = t("global.permission_denied")
          redirect_to params[:source] || items_path
        end
        format.js { render :json => {:success => false, :message => t("global.permission_denied") } }
        format.json { render :json => {:message => t("global.permission_denied")}, :status => :unprocessable_entity }
      end
    end
  end

  def current_scope
    scope.Images
  end

  def find_scope

      @item = Item.by_slug(params[:item_id])
      if @item
        @answer = @item.answers.find(params[:answer_id]) unless params[:answer_id].blank?
      end

  end

  def scope
    unless @answer.nil?
      @answer
    else
      @item
      #@discussion
    end
  end

  def full_scope
    unless @answer.nil?
      [@item, @answer]
    else
      [@item]
    end
  end
  helper_method :full_scope

end
