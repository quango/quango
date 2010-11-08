class SectionsController < ApplicationController
  before_filter :login_required
  before_filter :check_permissions
  layout "manage"
  tabs :default => :sections

  # GET /sections
  # GET /sections.json
  def index
    @section = Section.new
    @sections = @group.sections
  end

  # POST /sections
  # POST /sections.json
  def create

    if Section.types.include?(params[:section][:_type])
      @section = params[:section][:_type].constantize.new
    end

    @section.name = params[:section][:name]
    @section.node = params[:section][:node]
    @section.mode = params[:section][:mode]
    @section.hidden = params[:section][:hidden]
    @section.create_label = params[:section][:create_label]

    @group.sections << @section

    respond_to do |format|
      if @section.valid? && @group.save
        flash[:notice] = 'Section was successfully created.'
        format.html { redirect_to sections_path }
        format.json  { render :json => @section.to_json, :status => :created, :location => section_path(:id => @section.id) }
      else
        format.html { render :action => "index" }
        format.json  { render :json => @section.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit

  end

  # DELETE /ads/1
  # DELETE /ads/1.json
  def destroy
    @section = @group.sections.find(params[:id])
    @group.sections.delete(@section)
    @group.save

    respond_to do |format|
      format.html { redirect_to(sections_url) }
      format.json  { head :ok }
    end
  end

  def move
    section = @group.sections.find(params[:id])
    section.move_to(params[:move_to])
    redirect_to sections_path
  end

  private
  def check_permissions
    @group = current_group

    if @group.nil?
      redirect_to groups_path
    elsif !current_user.owner_of?(@group)
      flash[:error] = t("global.permission_denied")
      redirect_to ads_path
    end
  end
end
