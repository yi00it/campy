class ProjectMembershipsController < ApplicationController
  before_action :set_project
  before_action :authorize_project_owner!

  def create
    raw_email = membership_params[:email].to_s.strip
    email = raw_email.downcase
    user = User.where("lower(email) = ?", email).first

    if email.blank?
      redirect_to @project, alert: "Provide an email address." and return
    end

    if user.nil?
      invitation = @project.project_invitations.find_or_initialize_by(email: email)
      if invitation.persisted?
        redirect_to @project, notice: "An invitation has already been sent to #{raw_email}." and return
      end

      invitation.invited_by = current_user
      invitation.role = requested_role

      if invitation.save
        ProjectInvitationMailer.invite(invitation).deliver_now
        redirect_to @project, notice: "Invitation sent to #{raw_email}."
      else
        redirect_to @project, alert: invitation.errors.full_messages.to_sentence.presence || "Could not send invitation."
      end
      return
    end

    if user == @project.owner || @project.members.exists?(user.id)
      redirect_to @project, alert: "That user is already on the project." and return
    end

    membership = @project.project_memberships.build(user: user, role: requested_role)

    if membership.save
      @project.project_invitations.pending_for(email).find_each(&:accept!)
      redirect_to @project, notice: "#{user.display_name} added to the project."
    else
      message = membership.errors.full_messages.to_sentence.presence || "Could not add that user."
      redirect_to @project, alert: message
    end
  rescue ActiveRecord::RecordNotUnique
    redirect_to @project, alert: "That user is already on the project."
  end

  def update
    membership = @project.project_memberships.find(params[:id])
    if membership.update(role: requested_role)
      redirect_to @project, notice: "#{membership.user.display_name}'s role updated."
    else
      message = membership.errors.full_messages.to_sentence.presence || "Could not update role."
      redirect_to @project, alert: message
    end
  end

  def destroy
    membership = @project.project_memberships.find(params[:id])

    membership.destroy
    redirect_to @project, notice: "#{membership.user.display_name} removed from the project."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def membership_params
    params.fetch(:project_membership, {}).permit(:email, :role)
  end

  def authorize_project_owner!
    return if @project.owner_id == current_user.id

    redirect_to project_path(@project), alert: "Only the project owner can manage members." and return
  end

  def requested_role
    role = membership_params[:role].presence || "contributor"
    ProjectMembership::ROLES.include?(role) ? role : "contributor"
  end
end
