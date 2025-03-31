class Users::MyPageController < ApplicationController
  before_action :authenticate_user!
  layout "user"

  def show
  end

  def settings
  end
end
