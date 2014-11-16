module AuthenticationHelper

  def current_user
    return nil unless session[:token]
    @current_user ||= User.find_by_session_token(session[:token])
    (@current_user.kind_of?(User) &&
      @current_user.updated_at && 
      @current_user.updated_at > 10.minutes.ago) ?
        @current_user :
        nil
  end

  def login_redirect_params
    {controller: '/users', action: 'login',
      redirect_to: request.original_url}
  end

  def authenticate_user(email, password)
    user = User.find_by_email(email)
    if user then user.authenticate(password) else nil end
  end

  def create_session_for_user!(user)
    user.update_attributes(session_token: UUID.new.generate)
    session[:token] = user.session_token
  end

  class Authenticator
    include AuthenticationHelper
    attr_accessor :session, :request

    def self.for_session_and_request(session, request)
      i = new
      i.session = session
      i.request = request
      i
    end
  end
end
