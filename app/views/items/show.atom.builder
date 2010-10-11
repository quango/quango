atom_feed do |feed|
  feed.title("#{h(@item.title)} - #{current_group.name}")
  feed.updated(@item.updated_at)

  feed.entry(@item, :url => item_url(@item), :id =>"tag:#{@item.id}") do |entry|
    entry.title(h(@item.title))
    entry.content(markdown(@item.body), :type => 'html')
    entry.updated(@item.updated_at.strftime("%Y-%m-%dT%H:%M:%SZ"))
    entry.author do |author|
      author.name(h(@item.user.login))
    end
  end

  for answer in @answers
    next if answer.updated_at.blank?
    feed.entry(answer, :url => item_answer_url(@item, answer)) do |entry|
      entry.title("answer by #{h(answer.user.login)} for #{h(@item.title)}")
      entry.content(markdown(answer.body), :type => 'html')
      entry.author do |author|
        author.name(h(answer.user.login))
      end
    end
  end
end
