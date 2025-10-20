class AddRoleToProjectMembershipsAndInvitations < ActiveRecord::Migration[8.0]
  def change
    add_column :project_memberships, :role, :string, null: false, default: "contributor"
    add_column :project_invitations, :role, :string, null: false, default: "contributor"
  end
end
