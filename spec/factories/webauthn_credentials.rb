FactoryBot.define do
  factory :webauthn_credential do
    association :user
    external_id { SecureRandom.base64url(32) }
    public_key { "test_public_key_data_#{SecureRandom.hex(16)}" }
    nickname { "Test Passkey #{SecureRandom.hex(4)}" }
    sign_count { 0 }
  end
end
