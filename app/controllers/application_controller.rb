class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :set_theme

  helper_method :current_theme,
                :project_role,
                :project_membership,
                :can_manage_project?,
                :can_comment_on_activity?,
                :can_access_activity_files?,
                :can_message_user?

  private

  def set_theme
    @current_theme = current_user&.preferred_theme.presence_in(%w[light dark]) || "light"
  end

  def current_theme
    @current_theme
  end

  def project_membership(project)
    return nil if project.nil? || project.owner_id == current_user&.id

    @project_memberships_cache ||= {}
    @project_memberships_cache[project.id] ||= project.project_memberships.find_by(user: current_user)
  end

  def project_role(project)
    return :owner if project&.owner_id == current_user&.id
    project_membership(project)&.role&.to_sym
  end

  def can_manage_project?(project)
    %i[owner contributor].include?(project_role(project))
  end

  def can_comment_on_activity?(activity)
    role = project_role(activity.project)
    return true if %i[owner contributor].include?(role)

    role == :subcontractor && activity.assignee_id == current_user&.id
  end

  def can_access_activity_files?(activity)
    role = project_role(activity.project)
    return true if %i[owner contributor].include?(role)

    role == :subcontractor && activity.assignee_id == current_user&.id
  end

  def can_message_user?(user)
    return false if user.nil? || current_user.nil? || user.id == current_user.id

    current_user.teammate_ids.include?(user.id)
  end
end
