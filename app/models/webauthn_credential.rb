class WebauthnCredential < ApplicationRecord
  belongs_to :user

  validates :external_id, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :sign_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # WebAuthn gem integration
  include WebAuthn::Credential

  def self.find_by_external_id(external_id)
    find_by(external_id: external_id)
  end

  def update_sign_count!(sign_count)
    update!(sign_count: sign_count)
  end
end
