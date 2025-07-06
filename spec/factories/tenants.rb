FactoryBot.define do
  factory :tenant do
    name { Faker::Company.name }
    address { Faker::Address.full_address }
    web { "MyString" }
    tenant_mode { "single" }
    tenant_type { "subdomain" }
  end
end
