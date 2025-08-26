# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    session[:after_sign_in_redirect] = after_sign_in_path_for(resource)
    redirect_to users_verify_session_path
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # Handle authentication failures
  def failure
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)
    render :new
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  private

  def auth_options
    { scope: resource_name, recall: "#{controller_path}#failure" }
  end
end
