class ProfileImagesController < ApplicationController
  before_filter :login_required
  before_filter :set_profile_image
  #before_filter :check_permissions


  # GET /ProfileImages
  # GET /ProfileImages.json
  def index
    @profile_image = ProfileImage.new
    @profile_images = @user.profile_images
  end

  # POST /ProfileImages
  # POST /ProfileImages.json

  def new
    @profile_image = ProfileImage.new
    #@profile_images = @user.profile_images

  end


  def create
    @profile_image = ProfileImage.new

  end

  def edit
    @profile_image = @user.profile_image.find(params[:id])
  end

  def update
    @profile_image = @user.profile_images.find(params[:id])
    respond_to do |format|

      @profile_image.safe_update(%w[name], params[:profile_image])

      if @profile_image.valid? && @profile_image.save
        flash[:notice] = 'profile_image was successfully edited.'
        format.html { redirect_to profile_images_path }
        format.json  { render :json => @profile_image.to_json, :status => :created, :location => profile_image_path(:id => @profile_image.id) }
      else
        format.html { render :action => "index" }
        format.json  { render :json => @profile_image.errors, :status => :unprocessable_entity }
      end
    end
  end


  # DELETE /ads/1
  # DELETE /ads/1.json
  def destroy
    @profile_image = @user.profile_images.find(params[:id])
    @user.profile_images.delete(@profile_image)
    @user.save

    respond_to do |format|
      format.html { redirect_to(profile_images_url) }
      format.json  { head :ok }
    end
  end

  def move
    profile_image = @user.profile_images.find(params[:id])
    profile_image.move_to(params[:move_to])
    redirect_to profile_images_path
  end

  private

  def set_profile_image

     @profile_image = params[:profile_image]
     @profile_image
  end


  def check_permissions
    @user = current_user

    if @user.nil?
      redirect_to users_path
    elsif !current_user.owner_of?(@user)
      flash[:error] = t("global.permission_denied")
      redirect_to ads_path
    end
  end
end
