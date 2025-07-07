FactoryBot.define do
  factory :doorkeeper_access_token, class: 'Doorkeeper::AccessToken' do
    application { create(:doorkeeper_application) }
    resource_owner_id { create(:user).id }
    expires_in { 1.hour }
    scopes { 'read' }
  end
end 