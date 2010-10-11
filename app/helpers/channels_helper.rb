# Methods added to this helper will be available to all templates in the application.
module ChannelsHelper
  def autochannel(tags = [], options = {})
    if tags.empty?
      tags = Item.tag_cloud({:group_id => current_group.id, :banned => false}.
                        merge(language_conditions.merge(language_conditions)))
    end

    #First convert the tags into array
    cloud = ''
    tag_array = Array.new

    tags.each do |tag|
      tag_array << [tag["count"],tag["name"]]
    end

    sorted_array = tag_array.sort_by{|a|a.to_s}.reverse

    sorted_array[(1..8)].each do |s|
      #url = s.to_s
      url = url_for(:controller => "channels", :action => "index", :tags => s[1].to_s)
      cloud << "<li class='"+s[1].to_s+"'>#{link_to(s[1].capitalize, url)}"
      #if current_user.owner_of?(current_group)
       #cloud << "("+s[0].to_s+")"
      #end      
      cloud << "</li> "
    end
    cloud
  end
end

