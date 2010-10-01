module Sweepers
  def sweep_question_views
    expire_fragment("tag_cloud_#{current_group.id}")
  end

  def sweep_bookmark_views
    expire_fragment("tag_cloud_#{current_group.id}")
  end

  def sweep_discussion_views
    expire_fragment("tag_cloud_#{current_group.id}")
  end

  def sweep_answer_views
  end

  def sweep_user_views
    expire_fragment("new_users_#{current_group.id}")
  end

  def sweep_question(question)
    expire_fragment("question_on_index_#{question.id}")
    expire_fragment("mini_question_on_index_#{question.id}")
  end

  def sweep_bookmark(bookmark)
    expire_fragment("bookmark_on_index_#{bookmark.id}")
    expire_fragment("mini_bookmark_on_index_#{bookmark.id}")
  end

  def sweep_discussion(discussion)
    expire_fragment("discussion_on_index_#{discussion.id}")
    expire_fragment("mini_discussion_on_index_#{discussion.id}")
  end

  def sweep_new_users(group)
    expire_fragment("new_users_#{group.id}")
  end
end
