class User < ActiveRecord::Base
  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner
  has_secure_password(validations: false)

  validates_presence_of :password, on: [:create]
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }
  validates_uniqueness_of :email
end
