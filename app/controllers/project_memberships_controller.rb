class ProjectMembershipsController < ApplicationController
  before_action :set_project
  before_action :authorize_project_owner!

  def create
    email = membership_params[:email].to_s.strip.downcase
    user = User.where("lower(email) = ?", email).first

    if email.blank?
      redirect_to @project, alert: "Provide an email address." and return
    end

    if user.nil?
      redirect_to @project, alert: "No user found for #{email}." and return
    end

    if user == @project.owner || @project.members.exists?(user.id)
      redirect_to @project, alert: "That user is already on the project." and return
    end

    membership = @project.project_memberships.build(user: user)

    if membership.save
      redirect_to @project, notice: "#{user.email} added to the project."
    else
      message = membership.errors.full_messages.to_sentence.presence || "Could not add that user."
      redirect_to @project, alert: message
    end
  rescue ActiveRecord::RecordNotUnique
    redirect_to @project, alert: "That user is already on the project."
  end

  def destroy
    membership = @project.project_memberships.find(params[:id])

    membership.destroy
    redirect_to @project, notice: "#{membership.user.email} removed from the project."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def membership_params
    params.fetch(:project_membership, {}).permit(:email)
  end

  def authorize_project_owner!
    return if @project.owner_id == current_user.id

    redirect_to project_path(@project), alert: "Only the project owner can manage members." and return
  end
end
