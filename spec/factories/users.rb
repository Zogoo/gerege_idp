FactoryBot.define do
  factory :user do
    # first_name { Faker::Name.first_name }
    # last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    password { 'password123' }
    association :tenant
    # Add other user attributes as needed

    trait :facebook_oauth do
      provider { 'facebook' }
      uid { Faker::Number.number(digits: 15).to_s }
      name { Faker::Name.name }
      image { Faker::Internet.url(host: 'graph.facebook.com', path: '/picture') }
    end
  end
end
