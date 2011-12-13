class TransactionsController < ApplicationController
  skip_before_filter :check_group_access, :only => [:logo, :css, :favicon, :background]
  before_filter :login_required, :except => [:pages, :index, :show, :logo,:sponsor_logo_wide,:sponsor_logo_narrow,:group_style,:group_style_mobile, :css, :signup_button_css, :favicon, :background]
  before_filter :check_permissions, :only => [:edit, :update, :close]

  # GET /transactions
  # GET /transactions.xml
  def index
    @group = current_group
    @transactions = @group.transactions



    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @transactions }
    end
  end

  # GET /transactions/1
  # GET /transactions/1.xml
  def show
    @item = Item.find_by_slug_or_id(params[:item_id])
    @transaction = Transaction.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @transaction }
    end
  end

  # GET /transactions/new
  # GET /transactions/new.xml
  def new
    @item = Item.find_by_slug_or_id(params[:item_id])
    @transaction = Transaction.new
    @transaction.item = @item

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @transaction }
    end
  end

  # GET /transactions/1/edit
  def edit
    @transaction = Transaction.find(params[:id])
  end

  # POST /transactions
  # POST /transactions.xml
  def create
    @transaction = Transaction.new
    @transaction.safe_update(%w[name], params[:Transaction])
    @item = Item.find_by_slug_or_id(params[:item_id])
    @transaction.item = @item

    respond_to do |format|
      if @transaction.save
        format.html { redirect_to(item_transactions_path(@item.doctype_id, @item), :notice => 'Transaction was successfully created so it claims.') }
        format.xml  { render :xml => @transaction, :status => :created, :location => @transaction }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @transaction.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /transactions/1
  # PUT /transactions/1.xml

  def update
    @item = Item.find_by_slug_or_id(params[:item_id])
    @transaction = Transaction.find(params[:id])
    @transaction.safe_update(%w[name], params[:Transaction])

    respond_to do |format|
      if @transaction.save
        format.html { redirect_to(item_transactions_path(@item.doctype_id, @item), :notice => 'Transaction was successfully updated so it claims.') }
        format.xml  { render :xml => @transaction, :status => :created, :location => @transaction }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @transaction.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /transactions/1
  # DELETE /transactions/1.xml

  def destroy
    @item = Item.find_by_slug_or_id(params[:item_id])
    @transaction = Transaction.find(params[:id])
    @transaction.destroy

    respond_to do |format|
      format.html { redirect_to(item_transactions_path(@item.doctype_id, @item), :notice => 'Transaction was successfully deleted so it claims.') }
      format.xml  { head :ok }
    end
  end
end

#Break out the transactions
