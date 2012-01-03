class HeadersController < ApplicationController

  # GET /images
  # GET /images.xml

  def logos
  end

  def index
    @group = current_group
    @headers = current_group.headers
    

    @header = Header.find(params[:id])

    @default_header = Header.find(@group.default_header)

    #@header.group = @group

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @header }
    end
  end

  # GET /images/1
  # GET /images/1.xml
  def show
    @group = current_group
    @header = Header.find(params[:id])
    #

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @header }
    end
  end

  # GET /images/new
  # GET /images/new.xml
  def new
    @group = current_group
    @header = Header.new(params[:image])
    @header.group = @group


    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @header }
    end
  end

  # GET /images/1/edit
  def edit
    @header = Header.find(params[:id])
  end

  # POST /images
  # POST /images.xml
  def create

    @header = Header.new(params[:header])
    @header.safe_update(%w[name], params[:header])
    @group = current_group
    @header.group = @group
    #@header.name = @header.to_s
    @header.header = @header.header.process(:resize, '962>')

   

    respond_to do |format|
      if @header.save
        if params[:header][:header].present?
          format.html { redirect_to(crop_header_path(@header))}
          #format.html { redirect_to(headers_path)}
          #render :action => 'crop'
        else
          #format.html { render :action => "new" }
          format.xml  { render :xml => @header.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # PUT /images/1
  # PUT /images/1.xml

  def update
    @group = current_group
    @header = Header.find(params[:id])
    @header.safe_update(%w[name caption copyright copyright_url header_cropping], params[:header])

    if @group.default_header.blank?
        
        @group.default_header = params[:id]
        @group.save
    end 


    respond_to do |format|
      if @header.save
        
        format.html { redirect_to(headers_path, :notice => 'Header was successfully updated so it claims.') }
        format.xml  { render :xml => @header, :status => :created, :location => @header }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @header.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /images/1
  # DELETE /images/1.xml

  def destroy
    @group = current_group

    if @group.default_header == params[:id]
      @group.default_header = nil
      @group.save
    end

    @header = Header.find(params[:id])
    @header.destroy

    respond_to do |format|
      format.html { redirect_to(headers_path, :notice => 'Header was successfully deleted so it claims.') }
      format.xml  { head :ok }
    end
  end

  def move
    @group = Item.find_by_slug_or_id(params[:group_id])
    @header = Header.find(params[:id])
    @header.move_to(params[:move_to])
    redirect_to group_images_path
  end


  def crop

    @custom_header = true
    @custom_ua = true


    @group = current_group
    @header = Header.find(params[:id])



  end

  def flip
    @group = current_group
    @header = Header.find(params[:id])
    @header.image = @header.image.process!(:flip)
    @header.save

    respond_to do |format|
      format.html { redirect_to(crop_group_image_path, :notice => 'Header was successfully flipped so it claims.') }
    end

  end

  def flop
    @group = current_group
    @header = Header.find(params[:id])
    @header.image = @header.image.process!(:flop)
    @header.save

    respond_to do |format|
      format.html { redirect_to(crop_group_image_path, :notice => 'Header was successfully flopped so it claims.') }
    end
  end

  def rotate_right
    @group = current_group
    @header = Header.find(params[:id])
    @header.image = @header.image.process(:rotate, 5, :background_colour => 'white')
    @header.save
    respond_to do |format|
      format.html { redirect_to(crop_group_image_path, :notice => 'Header was successfully flopped so it claims.') }
    end
  end

  def rotate_left
    @group = current_group
    @header = Header.find(params[:id])
    @header.image = @header.image.process(:rotate, -5, :background_colour => 'white')
    @header.save
    respond_to do |format|
      format.html { redirect_to(crop_group_image_path, :notice => 'Header was successfully flopped so it claims.') }
    end
  end

  def rotate_180
    @group = current_group
    @header = Header.find(params[:id])
    @header.image = @header.image.process(:rotate, 180, :background_colour => 'white')
    @header.save
    respond_to do |format|
      format.html { redirect_to(crop_group_image_path, :notice => 'Header was successfully flopped so it claims.') }
    end
  end

  def set_default_header
    @group = current_group
    @header = Header.find_by_slug_or_id(params[:id])

    @group.default_header = @header.id


    if @group.save
      redirect_to headers_path 
    end


  end



end


#Break out the bunnies



