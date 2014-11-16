class Oauth::AuthorizationsController < Doorkeeper::AuthorizationsController
  layout "bare", only: [:new]
end
