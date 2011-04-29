class SponsorsController < ApplicationController

  # GET /sponsors
  # GET /sponsors.xml
  def index
    @item = Item.find_by_slug_or_id(params[:item_id])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sponsors }
    end
  end

  # GET /sponsors/1
  # GET /sponsors/1.xml
  def show
    @item = Item.find_by_slug_or_id(params[:item_id])
    @sponsor = sponsor.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @sponsor }
    end
  end

  # GET /sponsors/new
  # GET /sponsors/new.xml
  def new
    @item = Item.find_by_slug_or_id(params[:item_id])
    @sponsor = sponsor.new
    @sponsor.item = @item

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @sponsor }
    end
  end

  # GET /sponsors/1/edit
  def edit
    @sponsor = sponsor.find(params[:id])
  end

  # POST /sponsors
  # POST /sponsors.xml
  def create
    @sponsor = sponsor.new
    @sponsor.safe_update(%w[name], params[:sponsor])
    @item = Item.find_by_slug_or_id(params[:item_id])
    @sponsor.item = @item

    respond_to do |format|
      if @sponsor.save
        format.html { redirect_to(item_sponsors_path(@item.doctype_id, @item), :notice => 'sponsor was successfully created so it claims.') }
        format.xml  { render :xml => @sponsor, :status => :created, :location => @sponsor }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @sponsor.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sponsors/1
  # PUT /sponsors/1.xml

  def update
    @item = Item.find_by_slug_or_id(params[:item_id])
    @sponsor = sponsor.find(params[:id])
    @sponsor.safe_update(%w[name], params[:sponsor])

    respond_to do |format|
      if @sponsor.save
        format.html { redirect_to(item_sponsors_path(@item.doctype_id, @item), :notice => 'sponsor was successfully updated so it claims.') }
        format.xml  { render :xml => @sponsor, :status => :created, :location => @sponsor }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @sponsor.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sponsors/1
  # DELETE /sponsors/1.xml

  def destroy
    @item = Item.find_by_slug_or_id(params[:item_id])
    @sponsor = sponsor.find(params[:id])
    @sponsor.destroy

    respond_to do |format|
      format.html { redirect_to(item_sponsors_path(@item.doctype_id, @item), :notice => 'sponsor was successfully deleted so it claims.') }
      format.xml  { head :ok }
    end
  end
end

#Break out the sponsors
