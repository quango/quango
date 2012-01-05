class Subscription
  include MongoMapper::Document
  include MongoMapperExt::Filter

  TYPES = %w[free annual]


  key :_id, String
  key :_type, String
  key :name, String
  key :starts_at, Time
  key :ends_at, Time
  key :is_active, Boolean, :default => false
  

  timestamps!

  key :group, String
  belongs_to :group

  key :user, String
  belongs_to :user


  validates_presence_of :group
  validates_presence_of :user

end
