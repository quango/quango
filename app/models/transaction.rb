class Transaction
  include MongoMapper::Document
  include MongoMapperExt::Filter

  TYPES = %w[pending completed]


  key :_id, String
  key :_type, String
  key :name, String
  key :transaction_date, Time
  key :transaction_status, String

  timestamps!

  key :group_id, String
  belongs_to :group
  key :user_id, String
  belongs_to :user


  validates_presence_of :group_id
  validates_presence_of :user_id

end
