class Sessions::LaunchpadController < ApplicationController
  require_unauthenticated_access

  before_action :require_sig

  def show
  end

  def update
    if user = Current.account.signal_account.authenticate(sig: @sig).try(:peer)
      start_new_session_for user
      redirect_to after_authentication_url
    else
      render plain: "Authentication failed. This is probably a bug.", status: :unauthorized
    end
  end

  private
    def require_sig
      @sig = params.expect(:sig)
    end
end
