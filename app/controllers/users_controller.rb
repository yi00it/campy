class UsersController < ApplicationController
  before_action :set_user
  before_action :authorize_profile!

  def show
    @own_profile = @user == current_user

    @shared_projects = Project.accessible_to(current_user)
                               .left_outer_joins(:project_memberships)
                               .where("projects.owner_id = :user_id OR project_memberships.user_id = :user_id", user_id: @user.id)
                               .includes(:owner)
                               .distinct
                               .order(:name)

    @open_activities = @user.assigned_activities
                             .joins(:project)
                             .merge(Project.accessible_to(current_user))
                             .includes(:project, :discipline, :zone)
                             .where(is_done: false)
                             .order(Arel.sql("activities.due_on ASC NULLS LAST"),
                                    Arel.sql("activities.start_on ASC NULLS LAST"),
                                    :created_at)

    last_activity = @user.try(:current_sign_in_at) || @user.try(:last_sign_in_at) || @user.updated_at
    @online = last_activity.present? && last_activity > 10.minutes.ago
    @last_seen_at = last_activity

    @can_message = can_message_user?(@user)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def authorize_profile!
    return if @user == current_user || can_message_user?(@user)

    redirect_to authenticated_root_path, alert: "Not allowed."
  end
end
