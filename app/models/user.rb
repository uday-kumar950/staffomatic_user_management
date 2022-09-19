class User < ApplicationRecord
  include AdminType
  has_secure_password
  acts_as_paranoid
  has_many :notifications, as: :recipient
  validates :email, presence: true, uniqueness: true
  after_destroy      -> { create_log_versions(AdminType::ARCHIVE)}
  after_restore      -> { create_log_versions(AdminType::UNARCHIVE)}
  after_real_destroy -> { create_log_versions(AdminType::DELETE)}

  #create log after archive,unarchive and delete 
  def create_log_versions(type)
    PaperTrail::Version.create(item_type: "User", item_id: self.id, event: type, whodunnit: PaperTrail.request.whodunnit, object: self.to_yaml)
    Notification.create(notify_type: 'User', user_id: PaperTrail.request.whodunnit.to_i, target: self, message: "User #{type}")
  end

  def self.get_record(id)
      undeleted_user = User.find_by_id(id)
      return undeleted_user.blank? ? User.only_deleted.find_by_id(id) : undeleted_user
  end
  
  #get list of archived and unarchived records
  def self.get_list(type)
    if type == AdminType::ARCHIVE
      return User.only_deleted
    else
      return User.without_deleted
    end    
  end

  #archive,unarchive and delete user record
  def self.archive_unarchive(type, user)
    User.transaction do
      if type == AdminType::ARCHIVE
        user.destroy!
      elsif type == AdminType::UNARCHIVE
        user.restore!
      elsif type == AdminType::DELETE
        user.really_destroy!
      end
      puts EmailWorkerJob.new.perform(user.email, type) 
      return true
    rescue Exception => e
      return false
    end
  end

end
