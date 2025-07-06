class Tenant < ApplicationRecord
  has_many :users

  enum :tenant_mode, {
    single: "single",
    multi: "multi"
  }, suffix: true, default: :single

  enum :tenant_type, {
    subdomain: "subdomain",
  }, suffix: true, default: "subdomain"
end
