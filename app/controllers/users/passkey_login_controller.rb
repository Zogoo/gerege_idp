class Users::PasskeyLoginController < ApplicationController
  def create
    email = params[:email]
    user = User.find_by(email: email)

    if user&.has_webauthn_credentials?
      # Generate authentication options
      options = WebAuthn::Credential.options_for_get(
        allow: user.webauthn_credentials.pluck(:external_id)
      )

      session[:webauthn_authentication_challenge] = options.challenge
      session[:webauthn_authentication_user_id] = user.id

      # Debug logging
      Rails.logger.debug "WebAuthn auth options: #{options.inspect}"
      Rails.logger.debug "Challenge type: #{options.challenge.class}, value: #{options.challenge}"

      render json: options
    else
      # User doesn't have passkeys configured
      render json: { error: 'Invalid username or passkey. Please use password login or set up passkeys in your account settings.' }, status: :not_found
    end
  end

  def authenticate
    user = User.find(session[:webauthn_authentication_user_id])
    webauthn_credential = WebAuthn::Credential.from_get(params[:credential])

    begin
      # Find the stored credential
      stored_credential = user.webauthn_credentials.find_by!(external_id: webauthn_credential.id)

      # Verify the authentication
      webauthn_credential.verify(
        session[:webauthn_authentication_challenge],
        public_key: stored_credential.public_key,
        sign_count: stored_credential.sign_count
      )

      # Update sign count
      stored_credential.update_sign_count!(webauthn_credential.sign_count)

      # Sign in the user
      sign_in(user)

      session.delete(:webauthn_authentication_challenge)
      session.delete(:webauthn_authentication_user_id)

      render json: { success: true, redirect_url: after_sign_in_path_for(user) }
    rescue WebAuthn::Error => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end