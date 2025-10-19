class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :set_theme

  helper_method :current_theme

  private

  def set_theme
    @current_theme = current_user&.preferred_theme.presence_in(%w[light dark]) || "light"
  end

  def current_theme
    @current_theme
  end
end
