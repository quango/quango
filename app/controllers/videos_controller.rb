class VideosController < ApplicationController

  # GET /videos
  # GET /videos.xml

  def get_info
    @get_info = "Yo!"
    @get_info
  end

  def index
    @item = Item.find_by_slug_or_id(params[:item_id])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @videos }
    end
  end

  # GET /videos/1
  # GET /videos/1.xml
  def show
    @item = Item.find_by_slug_or_id(params[:item_id])
    @Video = Video.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @Video }
    end
  end

  # GET /videos/new
  # GET /videos/new.xml
  def new
    @item = Item.find_by_slug_or_id(params[:item_id])
    @Video = Video.new
    @Video.item = @item

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @Video }
    end
  end

  # GET /videos/1/edit
  def edit
    @Video = Video.find(params[:id])
  end

  # POST /videos
  # POST /videos.xml
  def create
    @Video = Video.new
    @Video.safe_update(%w[name], params[:Video])
    @item = Item.find_by_slug_or_id(params[:item_id])
    @Video.item = @item

    respond_to do |format|
      if @Video.save
        format.html { redirect_to(item_videos_path(@doctype, @item), :notice => 'Video was successfully created so it claims.') }
        format.xml  { render :xml => @Video, :status => :created, :location => @Video }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @Video.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /videos/1
  # PUT /videos/1.xml

  def update
    @item = Item.find_by_slug_or_id(params[:item_id])
    @Video = Video.find(params[:id])
    @Video.safe_update(%w[name], params[:Video])

    respond_to do |format|
      if @Video.save
        format.html { redirect_to(item_videos_path(@item.doctype_id, @item), :notice => 'Video was successfully updated so it claims.') }
        format.xml  { render :xml => @Video, :status => :created, :location => @Video }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @Video.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /videos/1
  # DELETE /videos/1.xml

  def destroy
    @item = Item.find_by_slug_or_id(params[:item_id])
    @Video = Video.find(params[:id])
    @Video.destroy

    respond_to do |format|
      format.html { redirect_to(item_videos_path(@item.doctype_id, @item), :notice => 'Video was successfully deleted so it claims.') }
      format.xml  { head :ok }
    end
  end
end

#Break out the videos
