class CloseRequestsController < ApplicationController
  before_filter :login_required
  before_filter :moderator_required, :only => [:index]
  before_filter :find_item
  before_filter :check_permissions, :except => [:create, :new, :index]

  def index
   if @item
    @close_requests = @item.close_requests
   end
  end

  def new
    @close_request = CloseRequest.new(:reason => "dupe")
    if @item
    respond_to do |format|
      format.html
      format.js do
        render :json => {:html => render_to_string(:partial => "close_requests/form",
                                                   :locals => {:item => @item,
                                                               :close_request => @close_request})}.to_json
        end
      end
    end
  end

  def create
    @close_request = CloseRequest.new(:reason => params[:close_request][:reason],
                                      :comment => params[:close_request][:comment])
    @close_request.user = current_user

    #Item
    if @item
      @item.close_requests << @close_request
      if current_user.mod_of?(current_group)
        @item.closed = Boolean.to_mongo(params[:close]||false)
        if @item.closed
          @item.close_reason_id = @close_request.id
        else
          @item.close_reason_id = nil
        end
      end

      respond_to do |format|
        if @close_request.valid?
          @item.save
          if @item.closed
            flash[:notice] = "item closed successfully"
          else
            flash[:notice] = t(:flash_notice, :scope => "close_requests.create")
          end
          format.html { redirect_to(item_path(@item)) }
          format.json { render :json => @close_request.to_json, :status => :created}
          format.js { render :json => {:message => flash[:notice], :success => true }.to_json }
        else
          flash[:error] = @close_request.errors.full_messages.join(", ")
          format.html { redirect_to(item_path(@item)) }
          format.json { render :json => @close_request.errors, :status => :unprocessable_entity}
          format.js { render :json => {:message => flash[:error], :success => false }.to_json }
        end
      end



    end
  end

  def edit
    if @item
      @close_request = @item.close_requests.find(params[:id])
      respond_to do |format|
        format.html
        format.js do
          render :json => {:html => render_to_string(:partial => "close_requests/form",
                                                     :locals => {:close_request => @close_request,
                                                                 :item => @item,
                                                                 :form_id => "item_close_form" })}.to_json
        end
      end
    end
  end

  def update
    #
    if @item
      @close_request = @item.close_requests.find(params[:id])
      @close_request.reason = params[:close_request][:reason]

      close_item = Boolean.to_mongo(params[:close]||false)
      if current_user.mod_of?(current_group)
        @item.closed = close_item
        if @item.closed_changed?
          if @item.closed
            @item.close_reason_id = @close_request.id
          else
            @item.close_reason_id = nil
          end
        end
      end

      respond_to do |format|
        if @close_request.valid?
          @item.save
          flash[:notice] = t(:flash_notice, :scope => "close_requests.update")
          format.html { redirect_to(item_path(@item)) }
          format.json { render :json => @close_request.to_json }
          format.js { render :json => {:message => flash[:notice], :success => true }.to_json }
        else
          flash[:error] = @close_request.errors.full_messages.join(", ")
          format.html { redirect_to(item_path(@item)) }
          format.json { render :json => @close_request.errors, :status => :unprocessable_entity}
          format.js { render :json => {:message => flash[:error], :success => false }.to_json }
        end
      end
    end
  end

  def destroy
    #
    if @item
      @close_request = @item.close_requests.find(params[:id])
      if @item.closed && @item.close_reason_id == @close_request.id
        @item.closed = false
      end
      @item.close_requests.delete(@close_request)

      @item.save
      flash[:notice] = t(:flash_notice, :scope => "close_requests.destroy")
      respond_to do |format|
        format.html { redirect_to(item_path(@item)) }
        format.json {head :ok}
        format.js { render :json => {:message => flash[:notice], :success => true}.to_json }
      end
    end
  end

  protected
  def find_item
    @item = current_group.items.find_by_slug_or_id(params[:item_id])
  end

  def check_permissions
    if @item
      @close_request = @item.close_requests.find(params[:id])
      if (@close_request && @close_request.user_id != current_user.id) ||
         (@item.closed && !current_user.mod_of?(current_group)) ||
         !@item.can_be_requested_to_close_by?(current_user)
        flash[:error] = t("global.permission_denied")
        respond_to do |format|
          format.html {redirect_to item_path(@item)}
          format.js {render :json => {:success => false, :message => flash[:error]}}
        end
        return
      end
    end
  end
end
