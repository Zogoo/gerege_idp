require 'rails_helper'

RSpec.describe WebauthnCredential, type: :model do
  let(:user) { create(:user) }
  let(:valid_attributes) do
    {
      user: user,
      external_id: "test_external_id_123",
      public_key: "test_public_key_data",
      nickname: "Test Passkey",
      sign_count: 0
    }
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      credential = WebauthnCredential.new(valid_attributes)
      expect(credential).to be_valid
    end

    it 'requires an external_id' do
      credential = WebauthnCredential.new(valid_attributes.except(:external_id))
      expect(credential).not_to be_valid
      expect(credential.errors[:external_id]).to include("can't be blank")
    end

    it 'requires a unique external_id' do
      WebauthnCredential.create!(valid_attributes)
      duplicate = WebauthnCredential.new(valid_attributes)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:external_id]).to include('has already been taken')
    end

    it 'requires a public_key' do
      credential = WebauthnCredential.new(valid_attributes.except(:public_key))
      expect(credential).not_to be_valid
      expect(credential.errors[:public_key]).to include("can't be blank")
    end

    it 'requires a non-negative sign_count' do
      credential = WebauthnCredential.new(valid_attributes.merge(sign_count: -1))
      expect(credential).not_to be_valid
      expect(credential.errors[:sign_count]).to include('must be greater than or equal to 0')
    end
  end

  describe 'associations' do
    it 'belongs to a user' do
      credential = WebauthnCredential.new(valid_attributes)
      expect(credential.user).to eq(user)
    end
  end

  describe 'class methods' do
    describe '.find_by_external_id' do
      it 'finds credential by external_id' do
        credential = WebauthnCredential.create!(valid_attributes)
        found = WebauthnCredential.find_by_external_id(credential.external_id)
        expect(found).to eq(credential)
      end
    end
  end

  describe 'instance methods' do
    describe '#update_sign_count!' do
      it 'updates the sign count' do
        credential = WebauthnCredential.create!(valid_attributes)
        credential.update_sign_count!(5)
        expect(credential.reload.sign_count).to eq(5)
      end
    end
  end
end
