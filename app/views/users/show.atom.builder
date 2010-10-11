atom_feed do |feed|
  title = "#{AppConfig.domain} - #{@user.login}'s Items"
  feed.title(title)
  unless @items.empty?
    feed.updated(@items.first.updated_at)
  end

  for item in @items
    next if item.nil? || item.updated_at.blank?
    feed.entry(item, :url => item_url(item)) do |entry|
      entry.title(item.title)
      entry.content(markdown(item.body), :type => 'html')
      entry.author do |author|
        author.name(item.user.login)
      end
    end
  end
end
