class ProjectInvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @project = invitation.project
    @inviter = invitation.invited_by
    @signup_url = new_user_registration_url(email: invitation.email)

    mail(
      to: invitation.email,
      subject: "You're invited to join #{@project.name} on Campy"
    )
  end
end
