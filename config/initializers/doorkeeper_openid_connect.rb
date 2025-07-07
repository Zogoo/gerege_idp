# frozen_string_literal: true

Doorkeeper::OpenidConnect.configure do
  issuer 'http://localhost:3000'

  signing_key Rails.application.credentials.openid_connect&.signing_key || 'test_secret_key_for_openid_connect'

  subject_types_supported [:public]

  resource_owner_from_access_token do |access_token|
    User.find(access_token.resource_owner_id)
  end

  auth_time_from_resource_owner do |resource_owner|
    resource_owner.current_sign_in_at if resource_owner.respond_to?(:current_sign_in_at)
  end

  reauthenticate_resource_owner do |resource_owner, return_to|
    store_location_for resource_owner, return_to if defined?(store_location_for)
    sign_out resource_owner if defined?(sign_out)
    redirect_to new_user_session_url if defined?(redirect_to)
  end

  subject do |resource_owner, application|
    resource_owner.id
  end

  # Protocol to use when generating URIs for the discovery endpoint,
  # for example if you also use HTTPS in development
  protocol do
    :https
  end

  # Expiration time on or after which the ID Token MUST NOT be accepted for processing. (default 120 seconds).
  # expiration 600

  # Example claims:
  # claims do
  #   normal_claim :_foo_ do |resource_owner|
  #     resource_owner.foo
  #   end

  #   normal_claim :_bar_ do |resource_owner|
  #     resource_owner.bar
  #   end

  #   claim :email do |resource_owner|
  #     resource_owner.email
  #   end

  #   claim :email_verified do |resource_owner|
  #     resource_owner.email_verified?
  #   end

  #   claim :name do |resource_owner|
  #     resource_owner.name
  #   end

  #   claim :nickname do |resource_owner|
  #     resource_owner.nickname
  #   end

  #   claim :picture do |resource_owner|
  #     resource_owner.picture_url
  #   end

  #   claim :updated_at do |resource_owner|
  #     resource_owner.updated_at
  #   end

  #   claim :email do |resource_owner|
  #     resource_owner.email
  #   end

  #   claim :email_verified do |resource_owner|
  #     resource_owner.email_verified?
  #   end

  #   claim :name do |resource_owner|
  #     resource_owner.name
  #   end

  #   claim :nickname do |resource_owner|
  #     resource_owner.nickname
  #   end

  #   claim :picture do |resource_owner|
  #     resource_owner.picture_url
  #   end

  #   claim :updated_at do |resource_owner|
  #     resource_owner.updated_at
  #   end
  # end
end 