FactoryBot.define do
  factory :user do
    username { Faker::Internet.username }
    email { Faker::Internet.email }
    password { Digest::SHA256.hexdigest("qwerty") }
  end
end
