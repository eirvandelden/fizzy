class SessionsController < ApplicationController
  def destroy
    terminate_session
    redirect_to Launchpad.login_url, allow_other_host: true
  end
end
