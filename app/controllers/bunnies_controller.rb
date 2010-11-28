class BunniesController < ApplicationController

  # GET /bunnies
  # GET /bunnies.xml
  def index
    @item = Item.find_by_slug_or_id(params[:item_id])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @bunnies }
    end
  end

  # GET /bunnies/1
  # GET /bunnies/1.xml
  def show
    @item = Item.find_by_slug_or_id(params[:item_id])
    @bunny = Bunny.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @bunny }
    end
  end

  # GET /bunnies/new
  # GET /bunnies/new.xml
  def new
    @item = Item.find_by_slug_or_id(params[:item_id])
    @bunny = Bunny.new
    @bunny.item = @item

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @bunny }
    end
  end

  # GET /bunnies/1/edit
  def edit
    @bunny = Bunny.find(params[:id])
  end

  # POST /bunnies
  # POST /bunnies.xml
  def create
    @bunny = Bunny.new
    @bunny.safe_update(%w[name], params[:bunny])
    @item = Item.find_by_slug_or_id(params[:item_id])
    @bunny.item = @item

    respond_to do |format|
      if @bunny.save
        format.html { redirect_to(item_bunnies_path(@item), :notice => 'Bunny was successfully created so it claims.') }
        format.xml  { render :xml => @bunny, :status => :created, :location => @bunny }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @bunny.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /bunnies/1
  # PUT /bunnies/1.xml

  def update
    @item = Item.find_by_slug_or_id(params[:item_id])
    @bunny = Bunny.find(params[:id])
    @bunny.safe_update(%w[name], params[:bunny])

    respond_to do |format|
      if @bunny.save
        format.html { redirect_to(item_bunnies_path(@item), :notice => 'Bunny was successfully updated so it claims.') }
        format.xml  { render :xml => @bunny, :status => :created, :location => @bunny }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @bunny.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /bunnies/1
  # DELETE /bunnies/1.xml

  def destroy
    @item = Item.find_by_slug_or_id(params[:item_id])
    @bunny = Bunny.find(params[:id])
    @bunny.destroy

    respond_to do |format|
      format.html { redirect_to(item_bunnies_path(@item), :notice => 'Bunny was successfully deleted so it claims.') }
      format.xml  { head :ok }
    end
  end
end

#Break out the bunnies
