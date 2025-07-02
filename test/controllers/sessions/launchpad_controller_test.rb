require "test_helper"

class Sessions::LaunchpadControllerTest < ActionDispatch::IntegrationTest
  test "show renders when not signed in" do
    get session_launchpad_path(params: { sig: "test-sig" })

    assert_response :success

    assert_select "form input#sig" do |node|
      assert_equal node.length, 1
      assert_equal node.first["value"], "test-sig"
    end
  end

  test "create establishes a session when the sig is valid" do
    user = users(:david)

    put session_launchpad_path(params: { sig: user.signal_user.perishable_signature })

    assert_redirected_to root_url
    assert parsed_cookies.signed[:session_token]
  end

  test "returns 401 when the sig is invalid" do
    user = users(:david)

    put session_launchpad_path(params: { sig: "invalid" })

    assert_response :unauthorized
  end
end
