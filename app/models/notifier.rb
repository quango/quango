class Notifier < ActionMailer::Base
  helper :application

  def give_advice(user, group, item, following = false)
    template_for user do

      scope = "mailers.notifications.give_advice"

      from "#{group.notification_from} <#{group.notification_email}>"
      recipients user.email

      if following
        subject I18n.t("friend_subject", :scope => scope, :item_title => item.title)
      else
        subject I18n.t("subject", :scope => scope, :item_title => item.title)
      end
      sent_on Time.now
      body   :user => user, :item => item,
             :group => group, :domain => group.domain,
             :following => following
    end
  end

  def new_answer(user, group, answer, following = false)
    self.class.layout "notification"
    template_for user do

      scope = "mailers.notifications.new_answer"
      if user == answer.item.user
        @subject = I18n.t("subject_owner", :scope => scope,
                                           :title => answer.item.title,
                                           :login => answer.user.login)
      elsif following
        @subject = I18n.t("subject_friend", :scope => scope,
                                            :title => answer.item.title,
                                            :login => answer.user.login)
      else
        @subject = I18n.t("subject_other", :scope => scope,
                                           :title => answer.item.title,
                                           :login => answer.user.login)
      end

      recipients user.email
      domain = group ? group.domain : AppConfig.domain
      from "#{group ? group.name : AppConfig.application_name} <#{AppConfig.notification_email}>"
      subject @subject
      sent_on Time.now
      body   :user => user, :answer => answer, :item => answer.item,
             :group => group, :domain => domain

      content_type  "text/html"
    end
  end

  def new_comment(group, comment, user, item)
    recipients user.email
    template_for user do
      from "Shapado <#{AppConfig.notification_email}>"
      subject I18n.t("mailers.notifications.new_comment.subject", :login => comment.user.login, :group => group.name)
      sent_on Time.now
      content_type    "multipart/alternative"

      body :user => user, :comment => comment, :item => item, :group => group
    end
  end

  def new_feedback(user, subject, content, email, ip)
    recipients AppConfig.exception_notification["exception_recipients"]
    from "Shapado[feedback] <#{AppConfig.notification_email}>"
    subject "feedback: #{subject}"
    sent_on Time.now
    body   :user => user, :subject => subject, :content => content, :email => email, :ip => ip
    content_type  "text/plain"
  end

  def follow(user, followed)
    recipients followed.email
    template_for followed do
      from "Shapado <#{AppConfig.notification_email}>"
      subject I18n.t("mailers.notifications.follow.subject", :login => user.login, :app => AppConfig.application_name)
      sent_on Time.now
      body :user => user, :followed => followed
    end
  end

  def earned_badge(user, group, badge)
    recipients user.email
    template_for user do

      from "Shapado <#{AppConfig.notification_email}>"
      subject I18n.t("mailers.notifications.earned_badge.subject", :group => group.name)
      sent_on Time.now
      body :user => user, :group => group, :badge => badge
      content_type    "multipart/alternative"
    end
  end

  def favorited(user, group, item)
    recipients item.user.email
    template_for item.user do

      from "Shapado <#{AppConfig.notification_email}>"
      subject I18n.t("mailers.notifications.favorited.subject", :login => user.login)
      sent_on Time.now
      body :user => user, :group => group, :item => item
      content_type    "multipart/alternative"
    end
  end

  def report(user, report)
    recipients user.email
    template_for user do
      from "Shapado <#{AppConfig.notification_email}>"
      subject I18n.t("mailers.notifications.report.subject", :group => report.group.name, :app => AppConfig.application_name)
      sent_on Time.now

      content_type    "text/plain"
      body :user => user, :report => report
    end
  end

  private
  def initialize_defaults(method_name)
    super
    @method_name = method_name
  end

  def template_for(user=nil, &block)
    old_lang = I18n.locale
    language = old_lang

    if user && user.language
      language = user.language
    end
    I18n.locale = language

    template_name = "#{@method_name}"
    if Dir.glob(RAILS_ROOT+"/app/views/notifier/#{template_name}*").size == 0
      template_name = @method_name
    end

    @template = template_name

    yield if block
    I18n.locale = old_lang
  end
end
