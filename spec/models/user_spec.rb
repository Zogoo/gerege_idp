require 'rails_helper'

RSpec.describe User, type: :model do
  it { should have_many(:access_grants).dependent(:delete_all) }
  it { should have_many(:access_tokens).dependent(:delete_all) }
  it { should belong_to(:tenant) }
  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:password).on(:create) }
  it { should validate_presence_of(:tenant_id) }

  describe "OAuth functionality" do
    let(:tenant) { create(:tenant) }
    let(:auth_hash) do
      OmniAuth::AuthHash.new({
        provider: 'facebook',
        uid: '123456789012345',
        info: {
          email: 'user@example.com',
          name: 'John Doe',
          image: 'https://graph.facebook.com/123456789012345/picture'
        }
      })
    end

    describe ".from_omniauth" do
      context "when user exists with same provider and uid" do
        let!(:existing_user) do
          create(:user, :facebook_oauth,
                 provider: 'facebook',
                 uid: '123456789012345',
                 tenant: tenant)
        end

        it "returns the existing user" do
          user = User.from_omniauth(auth_hash, tenant)
          expect(user).to eq(existing_user)
        end

        it "does not create a new user" do
          expect {
            User.from_omniauth(auth_hash, tenant)
          }.not_to change(User, :count)
        end
      end

      context "when user does not exist" do
        it "creates a new user" do
          expect {
            User.from_omniauth(auth_hash, tenant)
          }.to change(User, :count).by(1)
        end

        it "sets the correct attributes" do
          user = User.from_omniauth(auth_hash, tenant)
          
          expect(user.provider).to eq('facebook')
          expect(user.uid).to eq('123456789012345')
          expect(user.email).to eq('user@example.com')
          expect(user.name).to eq('John Doe')
          expect(user.image).to eq('https://graph.facebook.com/123456789012345/picture')
          expect(user.tenant).to eq(tenant)
        end

        it "generates a random password" do
          user = User.from_omniauth(auth_hash, tenant)
          expect(user.password).to be_present
          expect(user.password.length).to be >= 20
        end

        it "saves the user" do
          user = User.from_omniauth(auth_hash, tenant)
          expect(user).to be_persisted
        end
      end

      context "when user exists with same email but different provider" do
        let!(:existing_user) do
          create(:user, email: 'user@example.com', tenant: tenant)
        end

        it "links OAuth to existing user" do
          expect {
            User.from_omniauth(auth_hash, tenant)
          }.not_to change(User, :count)

          existing_user.reload
          expect(existing_user.provider).to eq('facebook')
          expect(existing_user.uid).to eq('123456789012345')
          expect(existing_user.name).to eq('John Doe')
          expect(existing_user.image).to eq('https://graph.facebook.com/123456789012345/picture')
        end
      end
    end

    describe "OAuth attributes" do
      let(:user) { create(:user, :facebook_oauth, tenant: tenant) }

      it "has OAuth attributes" do
        expect(user.provider).to eq('facebook')
        expect(user.uid).to be_present
        expect(user.name).to be_present
        expect(user.image).to be_present
      end
    end
  end

  describe "Devise modules" do
    it "includes omniauthable" do
      expect(User.devise_modules).to include(:omniauthable)
    end

    it "has Facebook as omniauth provider" do
      expect(User.omniauth_providers).to include(:facebook)
    end
  end
end
