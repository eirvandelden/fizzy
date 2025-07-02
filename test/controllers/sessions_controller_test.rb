require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "destroy" do
    sign_in_as :kevin
    delete session_path
    assert_redirected_to Launchpad.login_url
    assert_not cookies[:session_token].present?
  end
end
