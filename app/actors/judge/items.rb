module JudgeActions
  module Items
    def on_item_solved(payload)
      item_id, answer_id = payload
      item = Item.find(item_id)
      answer = Answer.find(answer_id)
      group = item.group

      if item.answer == answer && group.answers.count(:user_id => answer.user.id) == 1
        create_badge(answer.user, group, :token => "troubleshooter", :source => answer, :unique => true)
      end

      if item.answer == answer && answer.votes_average >= 10
        create_badge(answer.user, group, {:token => "enlightened", :source => answer}, {:unique => true, :source_id => answer.id})
      end

      if item.answer == answer && answer.votes_average >= 40
        create_badge(answer.user, group, {:token => "guru", :source => answer}, {:unique => true, :source_id => answer.id})
      end

      if item.answer == answer && answer.votes_average > 2
        answer.user.stats.add_expert_tags(*item.tags)
        create_badge(answer.user, group, :token => "tutor", :source => answer, :unique => true)
      end

      if item.user_id == answer.user_id
        create_badge(answer.user, group, :token => "scholar", :source => answer, :unique => true)
      end
    end

    def on_item_unsolved(payload)
      item_id, answer_id = payload
      item = Item.find(item_id)
      answer = Answer.find(answer_id)
      group = item.group

      if answer && item.answer.nil?
        user_badges = answer.user.badges
        badge = user_badges.first(:token => "troubleshooter", :group_id => group.id, :source_id => answer.id)
        badge.destroy if badge

        badge = user_badges.first(:token => "guru", :group_id => group.id, :source_id => answer.id)
        badge.destroy if badge
      end

      if answer && item.answer.nil?
        user_badges = answer.user.badges
        tutor = user_badges.first(:token => "tutor", :group_id => group.id, :source_id => answer.id)
        tutor.destroy if tutor
      end
    end

    def on_view_item(payload)
      item = Item.find!(payload.first)
      user = item.user
      group = item.group

      views = item.views_count
      opts = {:source_id => item.id, :source_type => "Item", :unique => true}
      if views >= 1000
        create_badge(user, group, {:token => "popular_item", :source => item}, opts)
      elsif views >= 2500
        create_badge(user, group, {:token => "notable_item", :source => item}, opts)
      elsif views >= 10000
        create_badge(user, group, {:token => "famous_item", :source => item}, opts)
      end
    end

    def on_ask_item(payload)
      item = Item.find!(payload.first)
      user = item.user
      group = item.group

      if group.items.count(:user_id => user.id) == 1
        create_badge(user, group, :token => "inquirer", :source => item, :unique => true)
      end
    end

    def on_destroy_item(payload)
      deleter = User.find(payload.first)
      attributes = payload.last
      group = Group.find(attributes["group_id"])

      if deleter.id == attributes["user_id"]
        if attributes["votes_average"] >= 3
          create_badge(deleter, group, :token => "disciplined", :unique => true)
        end

        if attributes["votes_average"] <= -3
          create_badge(deleter, group, :token => "peer_pressure", :unique => true)
        end
      end
    end

    def on_item_favorite(payload)
      item = Item.find(payload.first)
      user = item.user
      group = item.group
      if item.favorites_count >= 25
        create_badge(user, group, {:token => "favorite_item", :source => item}, {:unique => true, :source_id => item.id})
      end

      if item.favorites_count >= 100
        create_badge(user, group, {:token => "stellar_item", :source => item}, {:unique => true, :source_id => item.id})
      end
    end

    def on_retag_item(payload)
      item = Item.find(payload[0])
      user = User.find(payload[1])

      create_badge(user, item.group, {:token => "organizer", :source => item, :unique => true})
    end
  end
end
