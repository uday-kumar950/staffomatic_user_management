class UserMailer < ActionMailer::Base
  default from: "admin@example.com"
  layout 'mailer'
  def send_mail(email, subject)
    mail(to: email, subject: subject)
  end
 end