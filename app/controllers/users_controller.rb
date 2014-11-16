class UsersController < ApplicationController
  skip_before_filter :require_authentication, only: [:login, :handle_login]
  layout "bare", only: [:login]

  def login
    @redirect_to = params[:redirect_to]
  end

  def handle_login
    user = authenticate_user(params[:email], params[:password])
    create_session_for_user!(user) if user
    redirect_to(params[:redirect_to] || root_url)
  end

  def logout
    current_user.update_attributes(session_token: nil)
    redirect_to login_url
  end

end
