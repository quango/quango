desc "Setup application"
task :bootstrap => [:environment, "setup:reset",
                    "setup:create_admin",
                    "setup:create_user1",
                    "setup:create_user2",
                    "setup:default_group",
                    "setup:create_sections",
                    "setup:create_widgets",
                    "setup:create_pages"] do
end

desc "Upgrade"
task :upgrade => [:environment] do
end

namespace :setup do
  desc "Reset databases"
  task :reset => [:environment] do
    MongoMapper.connection.drop_database(MongoMapper.database.name)
  end

  desc "Reset admin password"
  task :reset_password => :environment do
    admin = User.find_by_login("admin")
    admin.encrypted_password = nil
    admin.password = "admins"
    admin.password_confirmation = "admins"
    admin.save
  end

  desc "Create the default group"
  task :default_group => [:environment] do
    default_tags = %w[something something-else]

    subdomain = AppConfig.application_name.gsub(/[^A-Za-z0-9\s\-]/, "")[0,20].strip.gsub(/\s+/, "-").downcase
    default_group = Group.new(:name => AppConfig.application_name,
                              :name_highlight => "domains",
                              :domain => AppConfig.domain,
                              :subdomain => subdomain,
                              :domain => AppConfig.domain,
                              :description => "Share your thoughts daily",
                              :legend => "Share your thoughts",
                              :default_tags => default_tags,
                              :state => "active")

    default_group.save!
    if admin = User.find_by_login("admin")
      default_group.owner = admin
      default_group.add_member(admin, "owner")
    end
    default_group.logo_path = "/images/thought_bubble_32.png"
    #default_group.logo.extension = "png"
    #default_group.logo.content_type = "image/png"



    default_group.save
  end

  desc "Create default widgets"
  task :create_widgets => :environment do
    default_group = Group.find_by_domain(AppConfig.domain)

    #if AppConfig.enable_groups
      #default_group.widgets << GroupsWidget.new
    #end
    default_group.widgets << TopUsersWidget.new
    default_group.save!
  end

  desc "Create default sections"
  task :create_sections => :environment do
    default_group = Group.find_by_domain(AppConfig.domain)

    doctypes = Array.new

    doctypes << Doctype.new(:name => "news", :doctype => "standard", :custom_icon => "news", :create_label => "Add some news", :group_id => default_group.id)
    doctypes << Doctype.new(:name => "thoughts", :doctype => "standard", :custom_icon => "thoughts", :create_label => "Share a thought", :group_id => default_group.id)
    doctypes << Doctype.new(:name => "newsfeeds", :doctype => "newsfeed", :custom_icon => "newsfeeds", :create_label => "Add a newsfeed", :hidden => "true", :group_id => default_group.id)
    doctypes << Doctype.new(:name => "discussions", :doctype => "standard", :custom_icon => "discussions", :create_label => "Discuss something", :group_id => default_group.id)
    doctypes << Doctype.new(:name => "articles", :doctype => "standard", :custom_icon => "articles", :create_label => "Write an article", :group_id => default_group.id)
    doctypes << Doctype.new(:name => "videos", :doctype => "video",:has_video => "true", :custom_icon => "videos", :create_label => "Share a video", :group_id => default_group.id)
    doctypes << Doctype.new(:name => "links", :doctype => "bookmark",:has_links => "true", :custom_icon => "links", :create_label => "Share a link", :group_id => default_group.id)

    doctypes.each do |doctype| 
     doctype.save!
    end

  end


  desc "Create admin user"
  task :create_admin => [:environment] do
    admin = User.new(:login => "admin", :password => "admins",
                                        :password_confirmation => "admins",
                                        :email => "admin@something.com",
                                        :first_name => "The",
                                        :last_name => "Administrator",
                                        :role => "admin")

    admin.save!
  end

  desc "Create user 1"
  task :create_user1 => [:environment] do
    user = User.new(:login => "user1", :password => "user123",
                                      :password_confirmation => "user123",
                                      :email => "user1@example.com",
                                      :first_name => "Gary",
                                      :last_name => "Baldie",
                                      :role => "user")
    user.save!
  end

  desc "Create user 2"
  task :create_user2 => [:environment] do
    user = User.new(:login => "user2", :password => "user123",
                                      :password_confirmation => "user123",
                                      :email => "user2@example.com",
                                      :first_name => "Ginger",
                                      :last_name => "Snap",
                                      :role => "user")
    user.save!
  end


  desc "Create pages"
  task :create_pages => [:environment] do
    Dir.glob(RAILS_ROOT+"/db/fixtures/pages/*.markdown") do |page_path|
      basename = File.basename(page_path, ".markdown")
      title = basename.gsub(/\.(\w\w)/, "").titleize
      language = $1

      body = File.read(page_path)

      puts "Loading: #{title.inspect} [lang=#{language}]"
      Group.find_each do |group|
        if Page.count(:title => title, :language => language, :group_id => group.id) == 0
          Page.create(:title => title, :language => language, :body => body, :user_id => group.owner, :group_id => group.id)
        end
      end
    end
  end

  desc "Reindex data"
  task :reindex => [:environment] do
    class Item
      def update_timestamps
      end
    end

    class Doctype
      def update_timestamps
      end
    end

    class Answer
      def update_timestamps
      end
    end

    class Group
      def update_timestamps
      end
    end

    class User
      def update_timestamps
      end
    end

    $stderr.puts "Reindexing #{Item.count} items..."
    Item.find_each do |item|
      item._keywords = []
      item.rolling_back = true
      item.save(:validate => false)
    end

    $stderr.puts "Reindexing #{Answer.count} answers..."
    Answer.find_each do |answer|
      answer._keywords = []
      answer.rolling_back = true
      answer.save(:validate => false)
    end

    $stderr.puts "Reindexing #{Group.count} groups..."
    Group.find_each do |group|
      group._keywords = []
      group.save(:validate => false)
    end
  end
end

