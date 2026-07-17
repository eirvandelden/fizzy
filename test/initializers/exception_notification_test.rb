# frozen_string_literal: true

require "test_helper"
require "open3"

class ExceptionNotificationTest < ActiveSupport::TestCase
  test "production boots without a Campfire webhook during image builds" do
    output, status = Open3.capture2e(
      { "RAILS_ENV" => "production", "SECRET_KEY_BASE_DUMMY" => "1", "CAMPFIRE_WEBHOOK_URL" => nil },
      "bin/rails", "runner", "puts :booted"
    )

    assert status.success?, output
  end
end
