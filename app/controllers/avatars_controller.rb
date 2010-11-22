class AvatarsController < ApplicationController
  before_filter :login_required
  before_filter :find_scope
  before_filter :check_permissions

  # GET /avatars
  def index
    @user = User.find_by_login_or_id(current_user.id)
    #@user = current_user.id

    #@avatars = @user.avatars

    @avatars = Avatar.all

    @user_avatars = Avatar.all



    #@avatars = Avatar.find(params[:user_id])

    #@user_avatars = @user.avatars
     # if avatar.user_id == @user
     #     @avatars << avatar
    #  end
    #end

  end

  # GET /avatars/1
  def show
    @user = User.find_by_login_or_id(params[:id])

    @avatar = Avatar.find(params[:id])


  end

  # GET /avatars/new
  def new
    @avatar = Avatar.new
  end

  # GET /avatars/1/edit
  def edit
    @avatar = Avatar.find(params[:id])
  end

  # POST /avatars
  def create
    @avatar = Avatar.new(params[:avatar])
    @avatar.user = current_user
    @avatar.avatar = @avatar.avatar.process!(:resize, '962x>')

    if @avatar.save
      if params[:avatar][:avatar].present?
        render :action => 'crop'
      else
        flash[:notice] = 'Avatar was successfully created.'
        redirect_to(@avatar)
      end
    else
      render :action => "new"
    end
  end

  def set_default
    @user = current_user
    @user.default_avatar = params[:id]

    if @user.update_attributes(params[:default_avatar])
        redirect_to avatars_path
    end
  end

  def set_profile
    @avatar = Avatar.find(params[:id])
    @user = current_user
    @user.profile_image = params[:id]
    @user.profile_image_link = @avatar.avatar.process(:thumb,@avatar.avatar_cropping)

    if @user.update_attributes(params[:profile_image])
        redirect_to avatars_path
    end
  end

  def update
    @avatar = Avatar.find(params[:id])

    if @avatar.update_attributes(params[:avatar])
      if params[:avatar][:avatar].present?
        render :action => 'crop'
      else
        flash[:notice] = 'Avatar was successfully updated.'
        redirect_to avatars_path
      end
    else
      render :action => "edit"
    end
  end

  # DELETE /avatars/1
  def destroy
    @avatar = Avatar.find(params[:id])
    @avatar.avatar.destroy!
    @avatar.destroy

    redirect_to(avatars_url)
  end

  # GET /avatars/1/crop
  def crop
    @avatar = Avatar.find(params[:id])
  end

  protected
  def find_scope
     @user = User.find_by_login_or_id(params[:id])
      if @user
        @avatar = @user.avatars.find(params[:user_id])
      end


  end

  def check_permissions

  end






end
