module ItemsHelper

  def has_images(item)
    if item.images
      return true
    else
      return false
    end
  end

  def microblogging_message(item)
    message = "#{h(item.title)}"
    message += " "
    message +=  escape_url(item_path(item, :only_path =>false))
    message
  end

  def linkedin_url(item)
    linkedin_share = item_path(item, :only_path =>false)
  end

  def video_thumbnail(item)
    video_thumbnail = "thumbnail.gif"
  end

  def share_url(item, service)
    url = ""
    case service
      when :twitter
        if logged_in? && current_user.twitter_token.present?
          url = twitter_share_url(:item_id => item.id)
        else
          url = "http://twitter.com/?status=#{microblogging_message(item)}"
        end
      when :think
        url = "http://linkedin.com/shareArticle?mini=true&url="+escape_url(item_url(item))+"&title=#{h(item.title)}&summary=#{h(item.body)}&source=#{current_group.name}"
      when :linkedin
        url = "http://linkedin.com/shareArticle?mini=true&url="+escape_url(item_url(item))+"&title=#{h(item.title)}&summary=#{h(item.body)}&source=#{current_group.name}"
      when :facebook
        if current_group.fb_button
          url = %@<iframe src="http://www.facebook.com/plugins/like.php?href=#{escape_url(item_path(item, :only_path =>false))}&amp;layout=button_count&amp;show_faces=true&amp;width=450&amp;action=like&amp;font&amp;colorscheme=light&amp;height=21" scrolling="no" frameborder="0" style="border:none; overflow:hidden; width:450px; height:21px;" allowTransparency="true"></iframe>@
        else
          fb_url = "http://www.facebook.com/sharer.php?u=#{escape_url(item_path(item, :only_path =>false))}&t=#{item.title}"
          url = %@#{image_tag('/images/share/facebook_32.png', :class => 'microblogging')} #{link_to("facebook", fb_url, :rel=>"nofollow external")}@
        end
    end
    url
  end

  protected
  def escape_url(url)
    URI.escape(url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end
end
