class Oauth::ApplicationsController < Doorkeeper::ApplicationsController
  include AuthenticationHelper

  def index
    @applications = current_user.oauth_applications
  end

  def create
    @application = Doorkeeper::Application.new(application_params)
    @application.owner = current_user
    if @application.save
      flash[:notice] = I18n.t(:notice, :scope => [:doorkeeper, :flash, :applications, :create])
       respond_with( :oauth, @application, location: oauth_application_url( @application ) )
    else
      render :new
    end
  end
end
