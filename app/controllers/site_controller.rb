class SiteController < ApplicationController

  def index
    redirect_url = current_user.admin? ?
      oauth_applications_url : oauth_authorized_applications_url
    redirect_to redirect_url
  end
end
