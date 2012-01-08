class WelcomeController < ApplicationController
  helper :items
  helper :channels

  tabs :default => :welcome
  subtabs :index => [[:fresh, "created_at desc"], [:heat, "hotness desc, views_count desc"], [:relevance, "votes_average desc"], [:activity, "activity_at desc"], [:expert, "created_at desc"]]

  def index
    @render_start = Time.now
    @active_subtab = params.fetch(:tab, "activity")
    conditions = scoped_conditions({:banned => false})

    current_order = ":heat"

    if params[:sort] == "hot"
      conditions[:activity_at] = {"$gt" => 7.days.ago}
    end

    @doctypes = current_group.doctypes

    #@doctype = @doctypes.find_by_slug_or_id(params[:doctype_id])
    @doctype = @doctypes.find(current_group.quick_create)

    @items = current_group.items #.merge(conditions)

    current_group.subscriptions.each do |subscription|
      if subscription.is_active?
        @subscription = subscription
      end
    end
    
    
   # @doctype = doctype

    #@item.doctype_id = @section.id


    #@section_items = current_group.current_section.items

    #@items = @items.sort_by(&:activity_at).reverse


    #@items = current_group.items.sort_by{|a,b| b.activity_at <=> a.activity_at} #({:order => "created_at"}.merge(conditions))
    #@items = current_group.items({:order => "created_at desc"}.merge(conditions))

    #@items = current_group.items.all({:order => current_order}.merge(conditions))

    #order = "hotness asc"

    #case @active_subtab
      #when "activity"
        #order = "activity_at desc"
     # when "hot"
        #order = "hotness desc"
        #conditions[:updated_at] = {:$gt => 5.days.ago}
    #end

    @langs_conds = conditions[:language][:$in]
    if logged_in?
      feed_params = { :feed_token => current_user.feed_token }
    else
      feed_params = {  :lang => I18n.locale,
                          :mylangs => current_languages }
    end
    add_feeds_url(url_for({:controller => 'items', :action => 'index',
                            :format => "atom"}.merge(feed_params)), t("feeds.items"))

    respond_to do |format|
      format.html # index.html.erb
      format.atom
    end



    #rstrict

      #options[:tags] = {:$all => @search_tags} unless @search_tags.empty?
      #options[:group_id] = current_group.id
      #options[:order] = params[:sort_by] if params[:sort_by]
      #options[:banned] = false


    #@items = Item.all #(options[:tags] = {:$all => current_group.default_tags} unless @search_tags.empty?)

    #@items = Item.paginate({:per_page => 15,
                                   #:page => params[:page] || 1,
                                   #:fields => (Item.keys.keys - ["_keywords", "watchers"]),
                                   #:order => order}.merge(conditions))
  end

  def feedback
  end

  def send_feedback
    ok = !params[:result].blank? &&
         (params[:result].to_i == (params[:n1].to_i * params[:n2].to_i))

    if ok && params[:feedback][:title].split(" ").size < 3
      single_words = params[:feedback][:description].split(" ").size
      ok = (single_words >= 3)

      links = words = 0
      params[:feedback][:description].split("http").map do |w|
        words += w.split(" ").size
        links += 1
      end

      if ok && links > 1 && words > 3
        ok = ((words-links) > 4)
      end
    end

    if !ok
      flash[:error] = I18n.t("welcome.feedback.captcha_error")
      flash[:error] += ". Domo arigato, Mr. Roboto. "
      redirect_to feedback_path(:feedback => params[:feedback])
    else
      Notifier.deliver_new_feedback(current_user, params[:feedback][:title],
                                                  params[:feedback][:description],
                                                  params[:feedback][:email],
                                                  request.remote_ip)
      redirect_to root_path
    end
  end

  def facts
  end


  def change_language_filter
    if logged_in? && params[:language][:filter]
      current_user.update_language_filter(params[:language][:filter])
    elsif params[:language][:filter]
      session["user.language_filter"] =  params[:language][:filter]
    end
    respond_to do |format|
      format.html {redirect_to(params[:source] || items_path)}
    end
  end

  def confirm_age
    if request.post?
      session[:age_confirmed] = true
    end

    redirect_to params[:source].to_s[0,1]=="/" ? params[:source] : root_path
  end

  #related items only relevant of quick create enabled

  def related_items
    if params[:id]
      @item = Item.find(params[:id])
    elsif params[:item]
      @item = Item.new(params[:item])
      @item.group_id = current_group.id
    end

    @item.tags += @item.title.downcase.split(",").join(" ").split(" ") if @item.title

    @items = Item.related_items(@item, :page => params[:page],
                                                       :per_page => params[:per_page],
                                                       :order => "answers_count desc",
                                                       :fields => {:_keywords => 0, :watchers => 0, :flags => 0,
                                                                  :close_requests => 0, :open_requests => 0,
                                                                  :versions => 0})

    respond_to do |format|
      format.js do
        render :json => {:html => render_to_string(:partial => "items/item",
                                                   :collection  => @items,
                                                   :locals => {:mini => true, :lite => true})}.to_json
      end
    end
  end



  protected

  def placeholder
  end

end

