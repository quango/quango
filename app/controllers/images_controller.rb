class ImagesController < ApplicationController

  # GET /images
  # GET /images.xml
  def index
    @item = Item.find_by_slug_or_id(params[:item_id])
    @image = Image.find(params[:id])
    #@image.items = @item

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @images }
    end
  end

  # GET /images/1
  # GET /images/1.xml
  def show
    @item = Item.find_by_slug_or_id(params[:item_id])
    @image = Image.find(params[:id])
    #

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @image }
    end
  end

  # GET /images/new
  # GET /images/new.xml
  def new
    @item = Item.find_by_slug_or_id(params[:item_id])
    @image = Image.new
    @image.item = @item

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @image }
    end
  end

  # GET /images/1/edit
  def edit
    @image = Image.find(params[:id])
  end

  # POST /images
  # POST /images.xml
  def create

    @image = Image.new(params[:image])
    @image.safe_update(%w[name], params[:image])
    @item = Item.find_by_slug_or_id(params[:item_id])
    @image.item = @item

    @image.image = @image.image.process!(:resize, '962>')

    respond_to do |format|
      if @image.save
        if params[:image][:image].present?
          render :action => 'crop'
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @image.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # PUT /images/1
  # PUT /images/1.xml

  def update
    @item = Item.find_by_slug_or_id(params[:item_id])
    @image = Image.find(params[:id])
    @image.safe_update(%w[name image_cropping], params[:image])

    respond_to do |format|
      if @image.save
        format.html { redirect_to(item_images_path(@item), :notice => 'Image was successfully updated so it claims.') }
        format.xml  { render :xml => @image, :status => :created, :location => @image }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @image.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /images/1
  # DELETE /images/1.xml

  def destroy
    @item = Item.find_by_slug_or_id(params[:item_id])
    @image = Image.find(params[:id])
    @image.destroy

    respond_to do |format|
      format.html { redirect_to(item_images_path(@item), :notice => 'Image was successfully deleted so it claims.') }
      format.xml  { head :ok }
    end
  end

  def crop
    @item = Item.find_by_slug_or_id(params[:item_id])
    @image = Image.find(params[:id])



  end

  def flip
    @item = Item.find_by_slug_or_id(params[:item_id])
    @image = Image.find(params[:id])
    @image.image = @image.image.process!(:flip)
    @image.save

    respond_to do |format|
      format.html { redirect_to(crop_item_image_path, :notice => 'Image was successfully flipped so it claims.') }
    end

  end

  def flop
    @item = Item.find_by_slug_or_id(params[:item_id])
    @image = Image.find(params[:id])
    @image.image = @image.image.process!(:flop)
    @image.save

    respond_to do |format|
      format.html { redirect_to(crop_item_image_path, :notice => 'Image was successfully flopped so it claims.') }
    end
  end

  def rotate_right
    @item = Item.find_by_slug_or_id(params[:item_id])
    @image = Image.find(params[:id])
    @image.image = @image.image.process(:rotate, 5, :background_colour => 'white')
    @image.save
    respond_to do |format|
      format.html { redirect_to(crop_item_image_path, :notice => 'Image was successfully flopped so it claims.') }
    end
  end

  def rotate_left
    @item = Item.find_by_slug_or_id(params[:item_id])
    @image = Image.find(params[:id])
    @image.image = @image.image.process(:rotate, -5, :background_colour => 'white')
    @image.save
    respond_to do |format|
      format.html { redirect_to(crop_item_image_path, :notice => 'Image was successfully flopped so it claims.') }
    end
  end

  def rotate_180
    @item = Item.find_by_slug_or_id(params[:item_id])
    @image = Image.find(params[:id])
    @image.image = @image.image.process(:rotate, 180, :background_colour => 'white')
    @image.save
    respond_to do |format|
      format.html { redirect_to(crop_item_image_path, :notice => 'Image was successfully flopped so it claims.') }
    end
  end


end


#Break out the bunnies



