class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable,
         omniauth_providers: [:facebook]

  belongs_to :tenant

  has_many :access_grants,
           class_name: 'Doorkeeper::AccessGrant',
           foreign_key: :resource_owner_id,
           dependent: :delete_all # or :destroy if you need callbacks

  has_many :access_tokens,
           class_name: 'Doorkeeper::AccessToken',
           foreign_key: :resource_owner_id,
           dependent: :delete_all # or :destroy if you need callbacks

  has_many :webauthn_credentials, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, on: :create
  validates :tenant_id, presence: true

  def self.from_omniauth(auth, tenant)
    # Handle invalid auth hash
    return nil if auth.nil? || auth.is_a?(Symbol)
    
    # First try to find by provider and uid
    user = where(provider: auth.provider, uid: auth.uid).first
    
    if user.nil?
      # If not found by provider/uid, try to find by email
      user = where(email: auth.info.email).first
      
      if user.nil?
        # Create new user if not found by either
        user = new do |u|
          u.email = auth.info.email
          u.password = Devise.friendly_token[0, 20]
          u.name = auth.info.name
          u.image = auth.info.image
          u.tenant = tenant
          u.provider = auth.provider
          u.uid = auth.uid
        end
        user.save!
      else
        # Update existing user with OAuth info
        user.update!(
          provider: auth.provider,
          uid: auth.uid,
          name: auth.info.name,
          image: auth.info.image
        )
      end
    end
    
    user
  end

  def has_webauthn_credentials?
    webauthn_credentials.any?
  end
end
