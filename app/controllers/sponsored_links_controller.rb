class SponsoredLinksController < ApplicationController

  # GET /sponsored_links
  # GET /sponsored_links.xml
  def index
    @sponsored_links = current_group.sponsored_links

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sponsored_links }
    end
  end

  # GET /sponsored_links/1
  # GET /sponsored_links/1.xml
  def show
    @item = Item.find_by_slug_or_id(params[:item_id])
    @sponsored_link = sponsored_link.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @sponsored_link }
    end
  end

  # GET /sponsored_links/new
  # GET /sponsored_links/new.xml
  def new

    @sponsored_link = SponsoredLink.new


    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @sponsored_link }
    end
  end

  # GET /sponsored_links/1/edit
  def edit
    @sponsored_link = SponsoredLink.find(params[:id])
  end

  # POST /sponsored_links
  # POST /sponsored_links.xml
  def create
    @sponsored_link = SponsoredLink.new
    @sponsored_link.safe_update(%w[name], params[:sponsored_link])

    @group = current_group

    @sponsored_link.group = @group


    respond_to do |format|
      if @sponsored_link.save
        format.html { redirect_to(sponsored_links_path, :notice => 'sponsored_link was successfully created so it claims.') }
        format.xml  { render :xml => @sponsored_link, :status => :created, :location => @sponsored_link }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @sponsored_link.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sponsored_links/1
  # PUT /sponsored_links/1.xml

  def update
    @sponsored_link = SponsoredLink.find(params[:id])

    @sponsored_link.safe_update(%w[name], params[:sponsored_link])

    respond_to do |format|
      if @sponsored_link.save
        format.html { redirect_to(manage_properties_path(:tab => "sponsored_links"), :notice => 'sponsored_link was successfully updated so it claims.') }
        format.xml  { render :xml => @sponsored_link, :status => :created, :location => @sponsored_link }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @sponsored_link.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sponsored_links/1
  # DELETE /sponsored_links/1.xml

  def destroy

    @sponsored_link = SponsoredLink.find(params[:id])
    @sponsored_link.destroy

    respond_to do |format|
      format.html { redirect_to(sponsored_links_path, :notice => 'sponsored_link was successfully deleted so it claims.') }
      format.xml  { head :ok }
    end
  end
end

#Break out the sponsored_links
