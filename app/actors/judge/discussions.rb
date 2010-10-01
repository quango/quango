module JudgeActions
  module Discussions
    def on_discussion_solved(payload)
      discussion_id, answer_id = payload
      discussion = Discussion.find(discussion_id)
      answer = Answer.find(answer_id)
      group = discussion.group

      if discussion.answer == answer && group.answers.count(:user_id => answer.user.id) == 1
        create_badge(answer.user, group, :token => "troubleshooter", :source => answer, :unique => true)
      end

      if discussion.answer == answer && answer.votes_average >= 10
        create_badge(answer.user, group, {:token => "enlightened", :source => answer}, {:unique => true, :source_id => answer.id})
      end

      if discussion.answer == answer && answer.votes_average >= 40
        create_badge(answer.user, group, {:token => "guru", :source => answer}, {:unique => true, :source_id => answer.id})
      end

      if discussion.answer == answer && answer.votes_average > 2
        answer.user.stats.add_expert_tags(*discussion.tags)
        create_badge(answer.user, group, :token => "tutor", :source => answer, :unique => true)
      end

      if discussion.user_id == answer.user_id
        create_badge(answer.user, group, :token => "scholar", :source => answer, :unique => true)
      end
    end

    def on_discussion_unsolved(payload)
      discussion_id, answer_id = payload
      discussion = Discussion.find(discussion_id)
      answer = Answer.find(answer_id)
      group = discussion.group

      if answer && discussion.answer.nil?
        user_badges = answer.user.badges
        badge = user_badges.first(:token => "troubleshooter", :group_id => group.id, :source_id => answer.id)
        badge.destroy if badge

        badge = user_badges.first(:token => "guru", :group_id => group.id, :source_id => answer.id)
        badge.destroy if badge
      end

      if answer && discussion.answer.nil?
        user_badges = answer.user.badges
        tutor = user_badges.first(:token => "tutor", :group_id => group.id, :source_id => answer.id)
        tutor.destroy if tutor
      end
    end

    def on_view_discussion(payload)
      discussion = Discussion.find!(payload.first)
      user = discussion.user
      group = discussion.group

      views = discussion.views_count
      opts = {:source_id => discussion.id, :source_type => "Discussion", :unique => true}
      if views >= 1000
        create_badge(user, group, {:token => "popular_discussion", :source => discussion}, opts)
      elsif views >= 2500
        create_badge(user, group, {:token => "notable_discussion", :source => discussion}, opts)
      elsif views >= 10000
        create_badge(user, group, {:token => "famous_discussion", :source => discussion}, opts)
      end
    end

    def on_ask_discussion(payload)
      discussion = Discussion.find!(payload.first)
      user = discussion.user
      group = discussion.group

      if group.discussions.count(:user_id => user.id) == 1
        create_badge(user, group, :token => "inquirer", :source => discussion, :unique => true)
      end
    end

    def on_destroy_discussion(payload)
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

    def on_discussion_favorite(payload)
      discussion = Discussion.find(payload.first)
      user = discussion.user
      group = discussion.group
      if discussion.favorites_count >= 25
        create_badge(user, group, {:token => "favorite_discussion", :source => discussion}, {:unique => true, :source_id => discussion.id})
      end

      if discussion.favorites_count >= 100
        create_badge(user, group, {:token => "stellar_discussion", :source => discussion}, {:unique => true, :source_id => discussion.id})
      end
    end

    def on_retag_discussion(payload)
      discussion = Discussion.find(payload[0])
      user = User.find(payload[1])

      create_badge(user, discussion.group, {:token => "organizer", :source => discussion, :unique => true})
    end
  end
end
