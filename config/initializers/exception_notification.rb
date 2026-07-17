# frozen_string_literal: true

if Rails.env.production? && (webhook_url = ENV["CAMPFIRE_WEBHOOK_URL"]).present?
  ExceptionNotification::Once::Campfire.install!(
    webhook_url: webhook_url,
    app_name: ENV.fetch("APP_NAME", Rails.application.class.module_parent_name),
    background: :active_job
  )
end
