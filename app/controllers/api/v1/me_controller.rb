class Api::V1::MeController < Api::V1::BaseController
  before_action :doorkeeper_authorize!
  # GET /me.json
  def me
    render json: current_resource_owner
  end
end
