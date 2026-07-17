class NotificationPusher
  def initialize(notification)
    @notification = notification
  end

  def push
    @notification.push
  end
end
