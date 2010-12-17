class Group
  include MongoMapper::Document
  include MongoMapperExt::Slugizer
  include MongoMapperExt::Storage
  include MongoMapperExt::Filter

  timestamps!

  BLACKLIST_GROUP_NAME = ["demo", "nigger", "wank", "cunt", "fuck", "www", "net", "org", "admin", "ftp", "mail", "test", "blog",
                 "bug", "bugs", "dev", "ftp", "forum", "community", "mail", "email",
                 "webmail", "pop", "pop3", "imap", "smtp", "stage", "stats", "status",
                 "support", "survey", "download", "downloads", "faqs", "wiki",
                 "assets1", "assets2", "assets3", "assets4", "staging"]

  key :_id, String
  key :parent_id, String #this will be used for groups hierarchies

  key :name, String, :required => true
  key :name_highlight, String
  key :subdomain, String
  key :domain, String
  key :legend, String
  key :description, String
  key :has_custom_channels, Boolean, :default => false
  key :custom_channels, Array #, :default => "something, something else"
  key :default_tags, Array
  key :has_custom_ads, Boolean, :default => true
  key :state, String, :default => "pending" #pending, active, closed
  key :isolate, Boolean, :default => false
  key :private, Boolean, :default => false
  key :theme, String, :default => "ping"
  key :owner_id, String
  key :has_bunnies, Boolean, :default => true

  #analytics
  key :robots, Boolean, :default => true
  key :analytics_id, String
  key :analytics_vendor, String
  key :has_custom_analytics, Boolean, :default => true

  key :language, String
  key :activity_rate, Float, :default => 0.0
  key :openid_only, Boolean, :default => false
  key :registered_only, Boolean, :default => false
  key :has_adult_content, Boolean, :default => false

  key :wysiwyg_editor, Boolean, :default => false

  key :has_reputation_constrains, Boolean, :default => true
  key :reputation_rewards, Hash, :default => REPUTATION_REWARDS
  key :reputation_constrains, Hash, :default => REPUTATION_CONSTRAINS
  key :forum, Boolean, :default => false

  key :custom_html, CustomHtml, :default => CustomHtml.new
  key :has_custom_html, Boolean, :default => true
  key :has_custom_js, Boolean, :default => true
  key :fb_button, Boolean, :default => true

  key :logo_path, String, :default => "/images/logos/star_32.png"
  key :favicon_path, String, :default => "/images/logos/thinking_favicon.png"

  key :image_of_the_day, String

  key :header_bg, String, :default => "#2b5782"
  key :header_bg_image, String
  key :toolbar_bg, String
  key :toolbar_bg_image, String, :default => "/images/black_25_bg.png"
  key :primary, String, :default => "#4183AF" #tabs, 
  key :primary_hover, String, :default => "#E1A970" #header_bg and edit buttons
  key :primary_selected, String, :default => "#990000"
  key :secondary, String, :default => "#72AFD7" #tabs,
  key :secondary_hover, String, :default => "orange"
  key :secondary_selected, String, :default => "#E1A970"
  key :secondary_active, String, :default => "#990000"
  key :tertiary, String, :default => "#8DBAD7" #tabs, 
  key :secondary_navigation_bg, String, :default => "gainsboro"
  key :secondary_navigation_text, String, :default => "white"
  key :edit_button_bg, String, :default => "#990000" #tabs, 
  key :edit_button_bg_image, String, :default => "/images/default_button_bg.png"
  key :link_colour, String, :default => "#4183AF"

  key :supplementary_dark, String, :default => "#A6691C" #action buttons and anything requiring high visibility
  key :supplementary, String, :default => "#FFB455" #action buttons and anything requiring high visibility
  key :supplementary_lite, String, :default => "#FFD6A2" #action buttons and anything requiring high visibility

  key :logo_info, Hash, :default => {"width" => 32, "height" => 32}
  key :share, Share, :default => Share.new

  #temp sections to be refactored with dynamic sections controller

  key :show_modes, Array #Hash, :default => Item::MODES
  key :show_modes_order, Hash


  #file_key :logo, :max_length => 2.megabytes
  #file_key :background, :max_length => 256.kilobytes
  file_key :custom_css, :max_length => 256.kilobytes
  #file_key :custom_favicon, :max_length => 256.kilobytes

  slug_key :name, :unique => true
  filterable_keys :name

  has_many :ads, :dependent => :destroy
  
  has_many :widgets, :class_name => "Widget"
  has_many :badges, :dependent => :destroy
  has_many :doctypes, :dependent => :destroy
  has_many :items, :dependent => :destroy
  has_many :answers, :dependent => :destroy
  has_many :votes, :dependent => :destroy
  has_many :pages, :dependent => :destroy
  has_many :announcements, :dependent => :destroy

  belongs_to :owner, :class_name => "User"

  has_many :comments, :as => "commentable", :order => "created_at asc", :dependent => :destroy

  validates_length_of       :name,           :within => 3..40
  validates_length_of       :description,    :within => 3..10000, :allow_blank => true
  validates_length_of       :legend,         :maximum => 50
  validates_length_of       :default_tags,   :within => 0..15,
      :message =>  I18n.t('activerecord.models.default_tags_message')
  validates_uniqueness_of   :name
  validates_uniqueness_of   :subdomain
  validates_presence_of     :subdomain
  validates_format_of       :subdomain, :with => /^[a-z0-9\-]+$/i
  validates_length_of       :subdomain, :within => 3..32

  validates_inclusion_of :language, :within => AVAILABLE_LANGUAGES, :allow_nil => true
  validates_inclusion_of :theme, :within => AVAILABLE_THEMES

  before_validation_on_create :check_domain
  before_save :disallow_javascript
  before_save :downcase_domain
  validate :check_reputation_configs

  validates_exclusion_of      :subdomain,
                              :within => BLACKLIST_GROUP_NAME,
                              :message => "Sorry, this group subdomain is reserved by"+
                                          " our system, please choose another one"

  def downcase_domain
    domain.downcase!
    subdomain.downcase!
  end

  def check_domain
    if domain.blank?
      self[:domain] = "#{subdomain}.#{AppConfig.domain}"
    end
  end

  def disallow_javascript
    unless self.has_custom_js
       %w[footer _head _item_help _item_prompt head_tag].each do |key|
         value = self.custom_html[key]
         if value.kind_of?(Hash)
           value.each do |k,v|
             value[k] = v.gsub(/<*.?script.*?>/, "")
           end
         elsif value.kind_of?(String)
           value = value.gsub(/<*.?script.*?>/, "")
         end
         self.custom_html[key] = value
       end
    end
  end

  def item_prompt
    self.custom_html.item_prompt[I18n.locale.to_s.split("-").first] || ""
  end

  def item_help
    self.custom_html.item_help[I18n.locale.to_s.split("-").first] || ""
  end

  def head
    self.custom_html.head[I18n.locale.to_s.split("-").first] || ""
  end

  def head_tag
    self.custom_html.head_tag
  end

  def footer
    self.custom_html.footer[I18n.locale.to_s.split("-").first] || ""
  end

  def item_prompt=(value)
    self.custom_html.item_prompt[I18n.locale.to_s.split("-").first] = value
  end

  def item_help=(value)
    self.custom_html.item_help[I18n.locale.to_s.split("-").first] = value
  end

  def head=(value)
    self.custom_html.head[I18n.locale.to_s.split("-").first] = value
  end

  def head_tag=(value)
    self.custom_html.head_tag = value
  end

  def footer=(value)
    self.custom_html.footer[I18n.locale.to_s.split("-").first] = value
  end

  def tag_list
    TagList.first(:group_id => self.id) || TagList.create(:group_id => self.id)
  end

  def default_tags=(c)
    if c.kind_of?(String)
      c = c.downcase.split(",").join(" ").split(" ")
    end
    self[:default_tags] = c
  end
  alias :user :owner

  def is_member?(user)
    user.member_of?(self)
  end

  def add_member(user, role)
    membership = user.config_for(self.id)
    if membership.reputation < 5
      membership.reputation = 5
    end
    membership.role = role

    user.save
  end

  def users(conditions = {})
    User.paginate(conditions.merge("membership_list.#{self.id}.reputation" => {:$exists => true}))
  end
  alias_method :members, :users

  def pending?
    state == "pending"
  end

  def on_activity(action)
    value = 0
    case action
      when :ask_item
        value = 0.1
      when :answer_item
        value = 0.3
    end

    self.collection.update({:_id => self._id}, {:$inc => {:activity_rate => value}},
                                                               :upsert => true)
  end

  def language=(lang)
    if lang != "none"
      self[:language] = lang
    else
      self[:language] = nil
    end
  end

  def self.humanize_reputation_constrain(key)
    I18n.t("groups.shared.reputation_constrains.#{key}", :default => key.humanize)
  end

  def self.humanize_reputation_rewards(key)
    I18n.t("groups.shared.reputation_rewards.#{key}", :default => key.humanize)
  end

  def check_reputation_configs
    if self.reputation_constrains_changed?
      self.reputation_constrains.each do |k,v|
        self.reputation_constrains[k] = v.to_i
        if !REPUTATION_CONSTRAINS.has_key?(k)
          self.errors.add(:reputation_constrains, "Invalid key")
          return false
        end
      end
    end

    if self.reputation_rewards_changed?
      valid = true
      [["vote_up_item", "undo_vote_up_item"],
       ["vote_down_item", "undo_vote_down_item"],
       ["item_receives_up_vote", "item_undo_up_vote"],
       ["item_receives_down_vote", "item_undo_down_vote"],
       ["vote_up_answer", "undo_vote_up_answer"],
       ["vote_down_answer", "undo_vote_down_answer"],
       ["answer_receives_up_vote", "answer_undo_up_vote"],
       ["answer_receives_down_vote", "answer_undo_down_vote"],
       ["answer_picked_as_solution", "answer_unpicked_as_solution"]].each do |action, undo|
        if self.reputation_rewards[action].to_i > (self.reputation_rewards[undo].to_i*-1)
          valid = false
          self.errors.add(undo, "should be less than #{(self.reputation_rewards[action].to_i)*-1}")
        end
      end
      return false unless valid

      self.reputation_rewards.each do |k,v|
        self.reputation_rewards[k] = v.to_i
        if !REPUTATION_REWARDS.has_key?(k)
          self.errors.add(:reputation_rewards, "Invalid key")
          return false
        end
      end
    end

    return true
  end
end
