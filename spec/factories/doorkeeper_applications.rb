FactoryBot.define do
  factory :doorkeeper_application, class: 'Doorkeeper::Application' do
    name { 'Test App' }
    redirect_uri { 'https://example.com' }
  end
end 