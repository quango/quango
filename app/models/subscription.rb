class Subscription
  include MongoMapper::Document
  include MongoMapperExt::Filter

  TYPES = %w[pending active expired]


  key :_id, String
  key :_type, String
  key :status, String, :default => "active"
  key :name, String
  key :starts_at, Timestamp, :required => true
  key :ends_at, Timestamp, :required => true
  key :is_active, Boolean, :default => true
  

  timestamps!

  key :group, String
  belongs_to :group

  key :user, String
  belongs_to :user


  #validates_presence_of :group
  #validates_presence_of :user

  validate :check_expiry


  def check_expiry

    if self.ends_at < Time.now
        self[:is_active] = false
        self[:status] = "expired"
    end  

  end

  protected

  def check_dates
    if self.starts_at < Time.now.yesterday
      self.errors.add(:starts_at, "Starting date should be setted to a future date")
    end

    if self.ends_at <= self.starts_at
      self.errors.add(:ends_at, "Ending date should be greater than starting date")
    end
  end
end
