# frozen_string_literal: true

class Users::SessionsConfirmationController < ApplicationController
  before_action :authenticate_user!
  layout "application"

  def show
    # Get the redirect location from session
    @redirect_location = session.delete(:after_sign_in_redirect) || after_sign_in_path_for(current_user)
    
    # Debug logging
    Rails.logger.info "SessionsConfirmation#show - redirect_location: #{@redirect_location}"
    Rails.logger.info "SessionsConfirmation#show - current_user: #{current_user&.email}"
  end
end
