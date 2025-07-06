FactoryBot.define do
  factory :tenant do
    name { Faker::Tenant.name }
    address { Faker::Address.full_address }
    web { "MyString" }
  end
end
