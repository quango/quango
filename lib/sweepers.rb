module Sweepers
  def sweep_item_views
    expire_fragment("tag_cloud_#{current_group.id}")
  end

  def sweep_answer_views
  end

  def sweep_user_views
    expire_fragment("new_users_#{current_group.id}")
  end

  def sweep_item(item)
    expire_fragment("item_on_index_#{item.id}")
    expire_fragment("mini_item_on_index_#{item.id}")
  end

  def sweep_new_users(group)
    expire_fragment("new_users_#{group.id}")
  end
end
