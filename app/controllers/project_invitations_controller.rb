class ProjectInvitationsController < ApplicationController
  before_action :set_project
  before_action :authorize_project_owner!

  def destroy
    invitation = @project.project_invitations.find(params[:id])
    invitation.destroy!
    redirect_to @project, notice: "Invitation to #{invitation.email} canceled."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def authorize_project_owner!
    return if @project.owner_id == current_user.id

    redirect_to project_path(@project), alert: "Only the project owner can manage invitations." and return
  end
end
