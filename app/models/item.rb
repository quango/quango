class Item
  include MongoMapper::Document
  include MongoMapperExt::Filter
  include MongoMapperExt::Slugizer
  include MongoMapperExt::Tags
  include Support::Versionable
  include Support::Voteable

  ensure_index :tags
  ensure_index :language

  VIDEO_MODES = %w{youtube vimeo another}

  key :_id, String
  key :section, String #TODO: replace with object
  key :mode, String
  key :type, String
  key :bookmark, String
  key :category, String, :required => false
  key :title, String, :required => true
  key :abstract, String
  key :description, String
  key :body, String

  slug_key :title, :unique => false, :min_length => 4
  key :slugs, Array, :index => true

  #video stuff (replace with model later)

  key :video_link, String
  key :video_thumbnail, String

  key :article_link, String
  key :article_link_author, String, :default => "Null"
  key :article_link_publisher, String, :default => "Null"

  #key :video_id, String
  #belongs_to :video

  key :default_thumbnail, String

  #meta
  
  key :meta_author, String, :default => "Null"
  key :meta_publisher, String, :default => "Null"
  key :meta_reference_link, String, :default => "Null"
  key :meta_title, String, :default => "Null"
  key :meta_abstract, String, :default => "Null"
  key :meta_description, String, :default => "Null"
  key :meta_keywords, String, :default => "Null"

  key :meta_robots, String, :default => "index,follow"
  key :meta_googlebot, String, :default => "INDEX,FOLLOW"
  key :meta_rating, String, :default => "General"
  key :meta_revisit_after, String, :default => "2 Days"

  key :answers_count, Integer, :default => 0, :required => true
  key :views_count, Integer, :default => 0
  key :images_count, Integer, :default => 0

  key :hotness, Integer, :default => 0
  key :flags_count, Integer, :default => 0
  key :favorites_count, Integer, :default => 0

  key :adult_content, Boolean, :default => false
  key :banned, Boolean, :default => false
  key :accepted, Boolean, :default => false
  key :closed, Boolean, :default => false
  key :closed_at, Time

  key :anonymous, Boolean, :default => false, :index => true
  key :anonymous_display_name, String    #used to pass email to user
  key :anonymous_email, String    #used to pass email to user

  key :answered_with_id, String
  belongs_to :answered_with, :class_name => "Answer"

  key :wiki, Boolean, :default => false
  key :language, String, :default => "en"

  key :activity_at, Time

  #key :section_id, String
  #belongs_to :section

  key :user_id, String, :index => true
  belongs_to :user

  key :answer_id, String
  belongs_to :answer

  key :image_id, String
  belongs_to :image

  key :bunny_id, String
  belongs_to :bunny

  key :group_id, String, :index => true
  belongs_to :group

  key :doctype, String

  key :doctype_id, String, :index => true
  belongs_to :doctype

  key :watchers, Array

  key :updated_by_id, String
  belongs_to :updated_by, :class_name => "User"

  key :close_reason_id, String

  key :last_target_type, String
  key :last_target_id, String
  key :last_target_date, Time

  belongs_to :last_target, :polymorphic => true

  has_many :distributors, :dependent => :destroy
  has_many :bunnies, :dependent => :destroy
  has_many :images, :dependent => :destroy
  has_many :answers, :dependent => :destroy
  has_many :badges, :as => "source"
  has_many :comments, :as => "commentable", :order => "created_at asc", :dependent => :destroy


  has_many :flags
  has_many :close_requests
  has_many :open_requests


  validates_presence_of :user_id
  validates_uniqueness_of :slug, :scope => :group_id, :allow_blank => true

  validates_length_of       :title,    :within => 3..100, :message => lambda { I18n.t("items.model.messages.title_too_long") }
  validates_length_of       :body,     :minimum => 5, :allow_blank => true, :allow_nil => true, :if => lambda { |q| !q.disable_limits? }
  validates_true_for :tags, :logic => lambda { tags.size <= 9},
                     :message => lambda { I18n.t("items.model.messages.too_many_tags") if tags.size > 9 }

  versionable_keys :title, :body, :tags
  filterable_keys :title, :body
  language :language

  before_save :update_activity_at
  before_validation_on_create :update_language

  validates_inclusion_of :language, :within => AVAILABLE_LANGUAGES
  validates_true_for :language, :logic => lambda { |q| q.group.language == q.language },
                                :if => lambda { |q| !q.group.language.nil? }
  validate :disallow_spam
  validate :check_useful

  timestamps!

  def first_tags
    tags[0..5]
  end

  def tags=(t)
    if t.kind_of?(String)
      t = t.downcase.split(",").join(" ").split(" ").uniq
    end

    self[:tags] = t
  end

  def first_locations
    locations[0..5]
  end

  def locations=(l)
    if l.kind_of?(String)
      l = l.downcase.split(",").join(" ").split(" ").uniq
    end

    self[:locations] = l
  end

  def self.related_items(item, opts = {})
    opts[:per_page] ||= 10
    opts[:page]     ||= 1
    opts[:group_id] = item.group_id
    opts[:banned] = false

    Item.paginate(opts.merge(:_keywords => {:$in => item.tags}, :_id => {:$ne => item.id}))
  end

  def viewed!(ip)
    view_count_id = "#{self.id}-#{ip}"
    if ViewsCount.find(view_count_id).nil?
      ViewsCount.create(:_id => view_count_id)
      self.increment(:views_count => 1)
    end
  end

  def answer_added!
    self.increment(:answers_count => 1)
    on_activity
  end

  def answer_removed!
    self.decrement(:answers_count => 1)
  end

  def image_added!
    self.increment(:images_count => 1)
    on_activity
  end

  def image_removed!
    self.decrement(:images_count => 1)
  end

  def flagged!
    self.increment(:flags_count => 1)
  end

  def on_add_vote(v, voter)
    if v > 0
      self.user.update_reputation(:item_receives_up_vote, self.group)
      voter.on_activity(:vote_up_item, self.group)
    else
      self.user.update_reputation(:item_receives_down_vote, self.group)
      voter.on_activity(:vote_down_item, self.group)
    end
    on_activity(false)
  end

  def on_remove_vote(v, voter)
    if v > 0
      self.user.update_reputation(:item_undo_up_vote, self.group)
      voter.on_activity(:undo_vote_up_item, self.group)
    else
      self.user.update_reputation(:item_undo_down_vote, self.group)
      voter.on_activity(:undo_vote_down_item, self.group)
    end
    on_activity(false)
  end

  def add_favorite!(fav, user)
    self.increment(:favorites_count => 1)
    on_activity(false)
  end


  def remove_favorite!(fav, user)
    self.decrement(:favorites_count => 1)
    on_activity(false)
  end

  def on_activity(bring_to_front = true)
    update_activity_at if bring_to_front
    self.increment(:hotness => 1)
  end

  def update_activity_at
    now = Time.now
    if new?
      self.activity_at = now
    else
      self.set(:activity_at => now)
    end
  end

  def ban
    self.set(:banned => true)
  end

  def self.ban(ids)
    # TODO: use mongo_mapper syntax
    self.collection.update({:_id => {:$in => ids}}, {:$set => {:banned => true}},
                                                     :multi => true)
  end

  def unban
    self.set(:banned => false)
  end

  def self.unban(ids)
    # TODO: use mongo_mapper syntax
    self.collection.update({:_id => {:$in => ids}}, {:$set => {:banned => false}},
                                                     :multi => true)
  end

  def favorite_for?(user)
    user.favorite(self)
  end


  def add_watcher(user)
    # TODO: use mongo_mapper syntax
    if !watch_for?(user)
      self.collection.update({:_id => self.id},
                             {:$push => {:watchers => user.id}});
    end
  end

  def remove_watcher(user)
    # TODO: use mongo_mapper syntax
    if watch_for?(user)
      self.collection.update({:_id => self.id},
                             {:$pull => {:watchers => user._id}});
    end
  end

  def watch_for?(user)
    watchers.include?(user._id)
  end

  def disable_limits?
    self.user.present? && self.user.can_post_whithout_limits_on?(self.group)
  end

  def check_useful
    unless disable_limits?
      if !self.title.blank? && self.title.gsub(/[^\x00-\x7F]/, "").size < 5
        return
      end

      if !self.title.blank? && (self.title.split.count < 0)
        self.errors.add(:title, I18n.t("items.model.messages.too_short", :count => 1))
      end

      if !self.body.blank? && (self.body.split.count < 4)
        self.errors.add(:body, I18n.t("items.model.messages.too_short", :count => 3))
      end
    end
  end

  def disallow_spam
    if new? && !disable_limits?
      last_item = Item.first( :user_id => self.user_id,
                                      :group_id => self.group_id,
                                      :order => "created_at desc")

      valid = (last_item.nil? || (Time.now - last_item.created_at) > 20)
      if !valid
        self.errors.add(:body, "Your item looks like spam. you need to wait 20 senconds before posting another item.")
      end
    end
  end

  def answered
    self.answered_with_id.present?
  end

  def self.update_last_target(item_id, target)
    # TODO: use mongo_mapper syntax
    self.collection.update({:_id => item_id},
                           {:$set => {:last_target_id => target.id,
                                      :last_target_type => target.class.to_s,
                                      :last_target_date => target.updated_at.utc}})
  end

  def can_be_requested_to_close_by?(user)
    ((self.user_id == user.id) && user.can_vote_to_close_own_item_on?(self.group)) ||
    user.can_vote_to_close_any_item_on?(self.group)
  end

  def can_be_requested_to_open_by?(user)
    return false if !self.closed
    ((self.user_id == user.id) && user.can_vote_to_open_own_item_on?(self.group)) ||
    user.can_vote_to_open_any_item_on?(self.group)
  end

  def can_be_deleted_by?(user)
    (self.user_id == user.id) || (self.closed && user.can_delete_closed_items_on?(self.group))
  end

  def close_reason
    self.close_requests.detect{ |rq| rq.id == close_reason_id }
  end

  protected
  def update_answer_count
    self.answers_count = self.answers.count
    votes_average = 0
    self.votes.each {|e| votes_average+=e.value }
    self.votes_average = votes_average

    self.votes_count = self.votes.count
  end

  def update_language
    self.language = self.language.split("-").first
  end



end

