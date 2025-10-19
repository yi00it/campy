class Conversation < ApplicationRecord
  has_many :conversation_memberships, dependent: :destroy
  has_many :users, through: :conversation_memberships
  has_many :messages, dependent: :destroy

  scope :for_user, ->(user) { joins(:conversation_memberships).where(conversation_memberships: { user_id: user.id }).distinct }

  def self.between(user_ids)
    joins(:conversation_memberships)
      .where(conversation_memberships: { user_id: user_ids })
      .group("conversations.id")
      .having("COUNT(DISTINCT conversation_memberships.user_id) = ?", user_ids.size)
  end
end
