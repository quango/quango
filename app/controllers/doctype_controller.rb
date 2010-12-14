class DoctypesController < ApplicationController
  before_filter :set_active_doctype

  # GET /bunnies
  # GET /bunnies.xml
  def index
    #@group = Group.find_by_slug_or_id(params[:group_id])

    @group = current_group


    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @bunnies }
    end
  end

  # GET /bunnies/1
  # GET /bunnies/1.xml
  def show
    @group = current_group
    #@group = Group.find_by_slug_or_id(params[:group_id])
    #@doctype = @active_doctype #"sausage"  #Doctype.find(params[:id])

    #@active_doctype = @doctype
    @doctype = Doctype.find_by_slug_or_id(params[:id])
    doctype = Doctype.find_by_slug_or_id(params[:id])
    #@sausage =  
    #@items = current_group.items.all

    @items = current_group.items.all #find(:all, :conditions => ["item.doctype_id = ?", params[:id]])

    @doctype_items = Array.new

    @items.each do |item|
      if item.doctype_id == doctype.id
        @doctype_items << item
      end
      @doctype_items
    end


     #age.find(:all, :conditions => [ "id != ? and publish = ? and category like "%?%", @page.id, true, @page.category ]) 

    #@items = @doctype.items #some sort of condition to only grab trhat doctype

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @doctype }
    end
  end

  # GET /bunnies/new
  # GET /bunnies/new.xml
  def new
    #@group = Group.find_by_slug_or_id(params[:group_id])
    @group = current_group

    @doctype = Doctype.new
    @doctype.group = @group

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @doctype }
    end
  end

  # GET /bunnies/1/edit
  def edit
    @doctype = Doctype.find(params[:id])
  end

  # POST /bunnies
  # POST /bunnies.xml
  def create
    @doctype = Doctype.new
    @doctype.safe_update(%w[name], params[:doctype])
    #@group = Group.find_by_slug_or_id(params[:group_id])
    @group = current_group

    @doctype.group = @group

    respond_to do |format|
      if @doctype.save
        format.html { redirect_to(doctypes_path, :notice => 'doctype was successfully created so it claims.') }
        format.xml  { render :xml => @doctype, :status => :created, :location => @doctype }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @doctype.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /bunnies/1
  # PUT /bunnies/1.xml

  def update
    @group = current_group
    @doctype = Doctype.find(params[:id])
    @doctype.safe_update(%w[name], params[:doctype])

    respond_to do |format|
      if @doctype.save
        format.html { redirect_to(doctypes_path, :notice => 'doctype was successfully updated so it claims.') }
        format.xml  { render :xml => @doctype, :status => :created, :location => @doctype }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @doctype.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /bunnies/1
  # DELETE /bunnies/1.xml

  def destroy
    @group = current_group
    @doctype = Doctype.find(params[:id])
    @doctype.destroy

    respond_to do |format|
      format.html { redirect_to(doctypes_path, :notice => 'doctype was successfully deleted so it claims.') }
      format.xml  { head :ok }
    end
  end

  def move
    doctype = @group.doctypes.find(params[:id])
    doctype.move_to(params[:move_to])
    redirect_to doctypes_path
  end

  def list
    #@group = Group.find_by_slug_or_id(params[:group_id])
    @doctype = Doctype.find_by_slug_or_id(params[:id])
    @items = current_group.items #.all


    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @doctype }
    end
  end

  protected
  def set_active_doctype

     @active_doctype = params[:doctype_id]

     #@item = Item.find_by_slug_or_id(params[:id])


     @doctypes = current_group.doctypes
        
  
     @doctypes.each do |doctype|
      
     if doctype.name == @active_doctype
        @active_doctype = doctype
     end

     end

     #@doctype = Section.find


     @active_doctype
  end




end

#Break out the bunnies
