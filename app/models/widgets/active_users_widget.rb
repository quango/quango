class ActiveUsersWidget < Widget
  before_validation_on_create :set_name
  before_validation_on_update :set_name

  def active_users(group)
    group.users(:order => "membership_list.#{group.id}.last_activity_at desc",
                :per_page => 4,
                :page => 1)
  end

  protected
  def set_name
    self[:name] ||= "active_users"
  end
end
