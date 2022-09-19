class EmailWorkerJob
  #include Sidekiq::Job
  include Sidekiq::Worker

  def perform(email, type)
    # Do something
    subject = ''
    if type == AdminType::ARCHIVE
      subject += "User with email ID #{email} archived"
    elsif type == AdminType::UNARCHIVE
      subject += "User with email ID #{email} unarchived"
    elsif type == AdminType::DELETE
      subject += "User with email ID #{email} permanently deleted"
    end
    UserMailer.send_mail(email, subject)
  end
end
