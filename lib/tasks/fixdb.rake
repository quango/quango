desc "Fix all"
task :fixall => [:environment, "fixdb:fixusers"] do
end

namespace :fixdb do

  task :fixusers => :environment do
    count = 0
    User.find_each do |user|
      count = count + 1
     	#user.set({:profile_images => "foo"})
    end
    puts "Updating #{count} users"
  end

  task :modes2nodes => :environment do
    count = 0
    Group.find_each do |group|

      Item.find_each(:group_id => group.id) do |item|
        count = count + 1
	      if item.mode == "bookmark"
              	item.set({:section => "bookmarks"})
	      end
	      if item.mode == "feature"
              	item.set({:section => "features"})
              	item.set({:mode => "discussion"})
	      end
	      if item.mode == "video"
              	item.set({:section => "video"})
	      end
	      if item.mode == "bug"
              	item.set({:section => "bugs"})
              	item.set({:mode => "discussion"})
	      end
	      if item.mode == "news_article"
              	item.set({:section => "news"})
              	item.set({:mode => "news"})
	      end
	      if item.mode == "discussion"
              	item.set({:section => "discussions"})
	      end
	      #item.set({})
      end
      puts "Updating #{count}  #{group["name"]}  items"
    end

  end

  task :badges => :environment do
    puts "Updating #{User.count} users..."

    Badge.set({:token => "tutor"}, {:type => "bronze"})

    User.find_each(:select => ["membership_list"]) do |user|
      user.membership_list.each do |group_id, membership|
        if membership["last_activity_at"].nil? && membership["reputation"] == 0
          user.unset(:"membership_list.#{group_id}")
        else
          gold_count = user.badges.count(:group_id => group_id, :type => "gold")
          bronze_count = user.badges.count(:group_id => group_id, :type => "bronze")
          silver_count = user.badges.count(:group_id => group_id, :type => "silver")
          editor = user.badges.first(:group_id => group_id, :token => "editor")

          if editor.present?
            user.set({"membership_list.#{group_id}.is_editor" => true})
          end

          user.set({"membership_list.#{group_id}.bronze_badges_count" => bronze_count})
          user.set({"membership_list.#{group_id}.silver_badges_count" => silver_count})
          user.set({"membership_list.#{group_id}.gold_badges_count" => gold_count})
        end
      end
    end
  end

  task :items => :environment do
    Group.find_each do |group|
      tag_list = group.tag_list

      Item.find_each(:group_id => group.id) do |item|
        if item.last_target.present?
          target = item.last_target
          item.set({:last_target_date => (target.updated_at||target.created_at).utc})
        elsif item.title.present?
          item.set({:last_target_date => (item.activity_at || item.updated_at).utc})
        end

        tag_list.add_tags(*item.tags)
      end
    end
  end

  task :update_widgets => :environment do
    Group.find_each do |group|
      puts "Updating #{group["name"]} widgets"

      MongoMapper.database.collection("widgets").find({:group_id => group["_id"]},
                                                      {:sort => ["position", :asc]}).each do |w|
        w.delete("position"); w.delete("group_id")
        MongoMapper.database.collection("groups").update({:_id => group["_id"]},
                                                         {:$addToSet => {:widgets => w}},
                                                         {:upsert => true, :safe => true})
      end
    end
    MongoMapper.database.collection("widgets").drop
  end

  task :tokens => :environment do
    User.find_each do |user|
      user.set({"feed_token" => UUIDTools::UUID.random_create.hexdigest,
                "authentication_token" => UUIDTools::UUID.random_create.hexdigest})
    end
  end

  task :reputation_rewards => :environment do
    Group.find_each do |g|
      [["vote_up_item", "undo_vote_up_item"],
       ["vote_down_item", "undo_vote_down_item"],
       ["item_receives_up_vote", "item_undo_up_vote"],
       ["item_receives_down_vote", "item_undo_down_vote"],
       ["vote_up_answer", "undo_vote_up_answer"],
       ["vote_down_answer", "undo_vote_down_answer"],
       ["answer_receives_up_vote", "answer_undo_up_vote"],
       ["answer_receives_down_vote", "answer_undo_down_vote"],
       ["answer_picked_as_solution", "answer_unpicked_as_solution"]].each do |action, undo|
         if g.reputation_rewards[action] > (g.reputation_rewards[undo]*-1)
           print "fixing #{g.name} #{undo} reputation rewards\n"
           g.set("reputation_rewards.#{undo}" => g.reputation_rewards[action]*-1)
         end
       end
    end
  end

  task :unsolve_items => :environment do
    Item.find_each(:accepted => true) do |q|
      if q.answer.nil?
        print "."
        q.set({:answer_id => nil, :accepted => false})
      end
    end
  end

  task :anonymous => :environment do
    User.set({}, {:anonymous => false})
  end

  task :flags => :environment do
    Group.find_each do |group|
      puts "Updating #{group["name"]} flags"
      count = 0

      MongoMapper.database.collection("flags").find({:group_id => group["_id"]}).each do |flag|
        count += 1
        flag.delete("group_id")
        id = flag.delete("flaggeable_id")
        klass = flag.delete("flaggeable_type")
        flag["reason"] = flag.delete("type")
        if klass == "Answer"
          obj = Answer.find(id)
        elsif klass == "Item"
          obj = Item.find(id)
        end
        p klass
        p id
        obj.add_to_set({:flags => flag})
      end
      puts count
    end
    MongoMapper.database.collection("falgs").drop
  end
end

