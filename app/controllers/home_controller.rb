class HomeController < ApplicationController
  def show
    return redirect_to new_user_session_path unless current_user
  end
end
