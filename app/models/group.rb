class Group
  include MongoMapper::Document
  include MongoMapperExt::Slugizer
  include MongoMapperExt::Storage
  include MongoMapperExt::Filter

  timestamps!

  BLACKLIST_GROUP_NAME = ["agent", "agents", "demo", "nigger", "wank", "cunt", "fuck", "www", "net", "org", "admin", "ftp", "mail", "test", "blog",
                 "bug", "bugs", "dev", "ftp", "forum", "community", "mail", "email",
                 "webmail", "pop", "pop3", "imap", "secure", "smtp", "stage", "stats", "status",
                 "support", "survey", "download", "downloads", "faqs", "wiki",
                 "assets1", "assets2", "assets3", "assets4", "staging"]

  key :_id, String
  key :parent_id, String #this will be used for groups hierarchies
  key :group_type, String, :default => "mobile"

  key :agent_id, String #stores the agent id

  key :sandwich_top, String

  key :title, String
  key :name, String, :required => true
  key :name_link, String

  slug_key :title, :unique => false, :min_length => 4
  key :slugs, Array, :index => true

  key :other_groups_facebook, String, :default => "http://www.facebook.com"
  key :other_groups_linkedin, String, :default => "http://www.linkedin.com"
  key :other_groups_twitter, String, :default => "http://www.twitter.com"
  key :other_groups_google, String, :default => "http://www.google.com"

  key :display_name_i, String, :default => "moFAQ"
  key :display_name_i_link, String, :default => "/"

  key :display_name_ii, String
  key :display_name_ii_link, String, :default => "/"

  key :name_highlight, String, :default => "daily"
  key :name_highlight_link, String, :default => "http://thinkingdaily.com.au"

  key :strapline, String

  key :subdomain, String
  key :domain, String
  key :legend, String, :default => "Every business needs a mobile FAQ"
  key :description, :default => "This mobile FAQ allows customers to ask questions and get answers about a business directly from their mobile phone or tablet."

  key :group_categories, Array
  key :show_category_navigation, Boolean, :default => false
  key :show_context_navigation, Boolean, :default => true

  key :has_custom_channels, Boolean, :default => false
  key :custom_channels, Array #, :default => "something, something else"
  key :custom_channel_content, String

  key :disable_signups, Boolean, :default => false

  #layouts
  key :has_leaderboard, Boolean, :default => false
  key :leaderboard_content, String

  key :has_bumper, Boolean, :default => false
  key :bumper_content, String

  key :has_custom_leaderboard, Boolean, :default => false
  key :custom_leaderboard_content, String

  key :has_medium_rectangle, Boolean, :default => false
  key :medium_rectangle_content, String

  key :has_threeone_rectangle, Boolean, :default => false
  key :threeone_rectangle_content, String

  key :standard_leaderboard, Boolean, :default => false
  key :standard_leaderboard_content, String

  key :welcome_layout, String, :default => "homepage_content_single"
  key :above_the_fold, Boolean, :default => false
  key :below_the_fold, Boolean, :default => true

  key :has_quick_create, Boolean, :default => false
  key :quick_create, String
  key :quick_create_heading, String, :default => "How can we help?"
  key :quick_create_label, String, :default => "Ask your question" #submit button

  key :has_welcome_features, Boolean, :default => false
  key :has_product_gallery, Boolean, :default => false
  key :has_video_on_homepage, Boolean, :default => false


  key :has_slideshow, Boolean,  :default => false
  key :slideshow_content, String,  :default => "articles"

  key :default_tags, Array
  key :has_custom_ads, Boolean, :default => true
  key :state, String, :default => "pending" #pending, active, closed
  key :isolate, Boolean, :default => false
  key :private, Boolean, :default => false
  key :hidden, Boolean, :default => false
  key :real_names, Boolean, :default => true
  key :theme, String, :default => "ping"
  key :owner_id, String
  key :has_bunnies, Boolean, :default => false
  key :show_group_create, Boolean, :default => true
  key :show_beta_links, Boolean, :default => true

  #email notifications
  key :notification_from, String, :default => "Your Community"
  key :notification_email, String, :default => "no-reply@yourcommunity.com"

  #api

  key :api_linkedin, Boolean, :default => false
  key :api_linkedin_key, String, :default => "my linkedin key"
  key :api_linkedin_secret, String, :default => "my linked key"

  key :has_alchemy, Boolean, :default => true
  key :alchemy_key, String, :default => "bf05bde28c9947946ac1e4481c3eac4350c1a546"
  key :yahoo_key, String, :default => "aLKN_v_V34HCd5jrNE_yrxFHExpd_AWLESH8KyD5zPLh7qc7nHsM54xn3P7H9lFquWtmRyHsvbjCB76uCWM-"


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

  key :share_box, Boolean, :default => true

  #labels
  key :publish_label, String, :default => "post"
  key :publish_label_past, String, :default => "posted"
  key :leaders_label, String, :default => "Thought leaders..." 
  key :about_label, String, :default => "How to use this website..." 
  key :signup_heading, String, :default => "Thinking is free, so naturally it free to share your thoughts..."  

  # theme
  key :logo_path, String, :default => "/images/logos/default-logo.png"
  key :logo_info, Hash, :default => {"width" => 64, "height" => 64}
  key :logo_only, Boolean, :default => false

  key :favicon_path, String, :default => "/images/logos/star_32.png"

  key :image_of_the_day, String

  key :header_bg, String, :default => "#2b5782"
  key :header_bg_image, String
  key :toolbar_bg, String
  key :toolbar_bg_image, String
  key :primary, String, :default => "#202020" #tabs, 
  key :primary_dark, String, :default => "#000000" #tabs, 
  key :primary_hover, String, :default => "#E1A970" #header_bg and edit buttons
  key :primary_selected, String, :default => "#990000"

  # to override the default
  key :has_custom_toolbar, Boolean, :default => false
  key :custom_toolbar_link, String
  key :custom_toolbar_image, String
  key :custom_toolbar_image_info, Hash, :default => {"width" => 64, "height" => 32}

  key :secondary, String, :default => "#404040" #tabs,
  key :secondary_hover, String, :default => "orange"
  key :secondary_selected, String, :default => "#E1A970"
  key :secondary_active, String, :default => "#990000"
  key :tertiary, String, :default => "#606060" #tabs, 
  key :complementary, String, :default => "#007500" #tabs, 

  key :secondary_navigation_bg, String, :default => "gainsboro"
  key :secondary_navigation_text, String, :default => "white"
  key :edit_button_bg, String, :default => "#990000" #tabs, 
  key :edit_button_bg_image, String, :default => "/images/default_button_bg.png"
  key :link_colour, String, :default => "#532a2a"
  key :text_colour, String, :default => "#ffffff"

  key :supplementary_dark, String, :default => "#A64300" #action buttons and anything requiring high visibility
  key :supplementary, String, :default => "#FF6600" #action buttons and anything requiring high visibility
  key :supplementary_lite, String, :default => "#FF8D40" #action buttons and anything requiring high visibility

  key :has_landing, Boolean, :default => true
  key :has_landing_bg, Boolean, :default => false
  key :landing_bg, String, :default => "/path/to/image"
  key :landing_labels, Hash, :default => {"heading" => "About this website","description" => "This website allows members to share information. Here you can engage in an open debate with experts in their fields and share your knowledge with others. ",
    "guest_heading" => "View site as guest", "guest_button" => "View site as guest", "guest_note" => "Guests cannot post content and/or comments",
    "signup_heading" => "Become a member - It's free & easy ", "signup_button" => ">> Become a member <<", "signup_note" => "All members can post content and/or comments",
    "login_heading" => "Already a member?", "login_button" => "Login now >>", "login_note" => ""
  }

  key :share, Share, :default => Share.new

  #temp sections to be refactored with dynamic sections controller

  key :show_modes, Array #Hash, :default => Item::MODES
  key :show_modes_order, Hash

  #community sponsor settings

  key :has_sponsor, Boolean, :default => false #headline sponsor


  key :sponsor_label, String, :default => "Supporters"
  key :sponsor_name, String
  key :sponsor_link, String

  key :show_sponsor_welcome, Boolean, :default => false #sponsor logo on welcome page
  key :show_sponsor_subsequent, Boolean, :default => false #sponsor logo on subsequent pages

  file_key :sponsor_logo_wide, :max_length => 256.kilobytes
  file_key :sponsor_logo_narrow, :max_length => 256.kilobytes
  key :sponsor_logo_wide_info, Hash, :default => {"width" => 256, "height" => 128}
  key :sponsor_logo_narrow_info, Hash, :default => {"width" => 140, "height" => 140}


  key :show_sponsor_description, Boolean, :default => false
  key :show_sponsor_description_boxheader, Boolean, :default => true
  key :sponsor_description_boxheader, String, :default => "About this sponsor..."
  key :sponsor_description, String


  key :has_sponsors, Boolean, :default => false #sponsored links
  key :sponsors_label, String, :default => "Sponsored links"


  #signup button

  key :show_signup_button, Boolean, :default => true
  key :signup_button_title, String, :default => "Contribute to this community"
  key :signup_button_description, String, :default => ""
  key :signup_button_label, String, :default => "Become a member"
  key :signup_button_footnote, String, :default => ""


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
  has_many :sponsored_links, :dependent => :destroy
  has_many :announcements, :dependent => :destroy
  has_many :subscriptions, :dependent => :destroy

  belongs_to :owner, :class_name => "User"

  has_many :comments, :as => "commentable", :order => "created_at asc", :dependent => :destroy

  validates_length_of       :name,           :within => 3..40
  validates_length_of       :description,    :within => 3..10000, :allow_blank => true
  validates_length_of       :legend,         :maximum => 50
  validates_length_of       :default_tags,   :within => 0..15, :message =>  I18n.t('activerecord.models.default_tags_message')
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
                              :message => "Sorry, this subdomain is not available please choose another one"

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
    self.custom_html.footer #[I18n.locale.to_s.split("-").first] || ""
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
    self.custom_html.footer #[I18n.locale.to_s.split("-").first] = value
  end

  def tag_list
    TagList.first(:group_id => self.id) || TagList.create(:group_id => self.id)
  end

  def group_categories=(gc)
    if gc.kind_of?(String)
      gc = gc.downcase.split(", ") #.join(" ").split(" ").flatten
      #gc = gc.downcase.split(/\s*?(".*?")\s*?/).map{|x| x=~/^".*"$/ ? x : x.split}.flatten
    end
    self[:group_categories] = gc
  end
  alias :user :owner

  def default_tags=(c)
    if c.kind_of?(String)
      c = c.downcase.split(", ").join(" ").split(" ")
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
