class Users::PasskeyManagementController < ApplicationController
  layout 'user'
  before_action :authenticate_user!
  before_action :set_credential, only: [:destroy]

  def index
    @credentials = current_user.webauthn_credentials
  end

  def new
    # Generate registration options for new passkey
    options = WebAuthn::Credential.options_for_create(
      user: {
        id: Base64.urlsafe_encode64(current_user.id.to_s, padding: false),
        name: current_user.email,
        display_name: current_user.name || current_user.email
      },
      exclude: current_user.webauthn_credentials.pluck(:external_id),
      authenticator_selection: { user_verification: 'required' }
    )

    session[:webauthn_registration_challenge] = options.challenge

    # Debug logging
    Rails.logger.debug "WebAuthn options: #{options.inspect}"
    Rails.logger.debug "Challenge type: #{options.challenge.class}, value: #{options.challenge}"

    render json: options
  end

  def create
    # Verify the registration response
    webauthn_credential = WebAuthn::Credential.from_create(params[:credential])

    begin
      webauthn_credential.verify(
        session[:webauthn_registration_challenge]
      )

      # Save the credential
      credential = current_user.webauthn_credentials.create!(
        external_id: webauthn_credential.id,
        public_key: webauthn_credential.public_key,
        nickname: params[:nickname] || "Passkey #{current_user.webauthn_credentials.count + 1}",
        sign_count: webauthn_credential.sign_count
      )

      session.delete(:webauthn_registration_challenge)

      render json: { success: true, credential: credential }
    rescue WebAuthn::Error => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def destroy
    @credential.destroy
    redirect_to users_passkey_management_index_path, notice: 'Passkey was successfully removed.'
  end

  private

  def set_credential
    @credential = current_user.webauthn_credentials.find(params[:id])
  end
end