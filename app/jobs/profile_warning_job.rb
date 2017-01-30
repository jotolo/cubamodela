class ProfileWarningJob < ApplicationJob
  queue_as :default

  def perform(profile)
    Notification.notify_profile_warning(profile)
    CastingMailer.email_profile_warning(profile).deliver_now
  end
end
