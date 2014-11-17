class UsersController < ApplicationController
  skip_before_filter :require_authentication, 
    only: [:login, :handle_login, :signup, :handle_signup]
  layout "bare", only: [:login, :signup]

  def signup
    save_redirect
  end

  def handle_signup
    user = User.new(email: params[:email], password: params[:password])
    if user.save
      login_and_redirect(user)
    else
      flash[:danger] = user.errors.full_messages.join("<br />")
      redirect_to signup_url
    end
  end

  def login
    save_redirect
  end

  def handle_login
    user = authenticate_user(params[:email], params[:password])
    if user
      login_and_redirect(user)
    else
      flash[:danger] = "Invalid username and/or password"
      redirect_to login_url
    end
  end

  def logout
    current_user.update_attributes(session_token: nil)
    redirect_to login_url
  end

  private

    def save_redirect
      @redirect_to = params[:redirect_to]
    end

    def login_and_redirect(user)
      create_session_for_user!(user) if user
      redirect_to(params[:redirect_to] || root_url)
    end
end
