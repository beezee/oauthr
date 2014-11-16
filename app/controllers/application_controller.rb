class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include AuthenticationHelper

  before_filter :require_authentication

  def require_authentication
    redirect_to(login_redirect_params) unless current_user
  end
end
