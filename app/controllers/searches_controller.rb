class SearchesController < ApplicationController
  def index
    options = {:per_page => 11, :page => params[:page] || 1}
    unless params[:q].blank?
      pharse = params[:q].downcase
      @search_tags = pharse.scan(/\[(\w+)\]/).flatten
      @search_text = pharse.gsub(/\[(\w+)\]/, "")
      options[:tags] = {:$all => @search_tags} unless @search_tags.empty?
      options[:group_id] = current_group.id
      #options[:order] = params[:sort] 
      options[:banned] = false
      
      #if !params[:sort].blank?
        #options[:order] = params[:sort] 
     # end

      if params[:sort] == "hot"
        options[:order] = "desc"
      end


      if !@search_text.blank?
        q = @search_text.split.map do |k|
          Regexp.escape(k)
        end.join("|")
        @query_regexp = /(#{q})/i
        @items = Item.filter(@search_text, options)
      else
        @items = Item.paginate(options)
      end
    else
      @items = []
    end

    respond_to do |format|
      format.html
      format.js do
        render :json => {:html => render_to_string(:partial => "items/item",
                                                   :collection  => @items)}.to_json
      end
      format.json { render :json => @items.to_json(:except => %w[_keywords slugs watchers]) }
    end
  end
end
