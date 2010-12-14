class SuctionsController < ApplicationController
  before_filter :set_active_section

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
    #@suction = @active_section #"sausage"  #Suction.find(params[:id])

    #@active_section = @suction
    @suction = Suction.find_by_slug_or_id(params[:id])
    suction = Suction.find_by_slug_or_id(params[:id])
    #@sausage =  
    #@items = current_group.items.all

    @items = current_group.items.all #find(:all, :conditions => ["item.suction_id = ?", params[:id]])

    @suction_items = Array.new

    @items.each do |item|
      if item.suction_id == suction.id
        @suction_items << item
      end
      @suction_items
    end


     #age.find(:all, :conditions => [ "id != ? and publish = ? and category like "%?%", @page.id, true, @page.category ]) 

    #@items = @suction.items #some sort of condition to only grab trhat section

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @suction }
    end
  end

  # GET /bunnies/new
  # GET /bunnies/new.xml
  def new
    #@group = Group.find_by_slug_or_id(params[:group_id])
    @group = current_group

    @suction = Suction.new
    @suction.group = @group

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @suction }
    end
  end

  # GET /bunnies/1/edit
  def edit
    @suction = Suction.find(params[:id])
  end

  # POST /bunnies
  # POST /bunnies.xml
  def create
    @suction = Suction.new
    @suction.safe_update(%w[name], params[:suction])
    #@group = Group.find_by_slug_or_id(params[:group_id])
    @group = current_group

    @suction.group = @group

    respond_to do |format|
      if @suction.save
        format.html { redirect_to(suctions_path, :notice => 'suction was successfully created so it claims.') }
        format.xml  { render :xml => @suction, :status => :created, :location => @suction }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @suction.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /bunnies/1
  # PUT /bunnies/1.xml

  def update
    @group = current_group
    @suction = Suction.find(params[:id])
    @suction.safe_update(%w[name], params[:suction])

    respond_to do |format|
      if @suction.save
        format.html { redirect_to(suctions_path, :notice => 'suction was successfully updated so it claims.') }
        format.xml  { render :xml => @suction, :status => :created, :location => @suction }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @suction.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /bunnies/1
  # DELETE /bunnies/1.xml

  def destroy
    @group = current_group
    @suction = Suction.find(params[:id])
    @suction.destroy

    respond_to do |format|
      format.html { redirect_to(suctions_path, :notice => 'suction was successfully deleted so it claims.') }
      format.xml  { head :ok }
    end
  end

  def move
    suction = @group.suctions.find(params[:id])
    suction.move_to(params[:move_to])
    redirect_to suctions_path
  end

  def list
    #@group = Group.find_by_slug_or_id(params[:group_id])
    @suction = Suction.find_by_slug_or_id(params[:id])
    @items = current_group.items #.all


    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @suction }
    end
  end

  protected
  def set_active_section

     @active_section = params[:suction_id]

     #@item = Item.find_by_slug_or_id(params[:id])


     @suctions = current_group.sections
        
  
     @suctions.each do |suction|
      
     if suction.name == @active_section
        @active_suction = suction
     end

     end

     #@section = Section.find


     @active_section
  end




end

#Break out the bunnies
