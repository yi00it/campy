class CreateProjectInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :project_invitations do |t|
      t.references :project, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :email, null: false
      t.string :token, null: false
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :project_invitations, [:project_id, :email], unique: true
    add_index :project_invitations, :token, unique: true
  end
end
