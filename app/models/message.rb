class Message < ApplicationRecord
  include ActionView::RecordIdentifier
  belongs_to :conversation, touch: true
  belongs_to :user

  validates :body, presence: true

  after_create_commit :broadcast_message
  after_create_commit :broadcast_conversation_previews

  private

  def broadcast_message
    broadcast_append_to conversation, target: dom_id(conversation, :messages), partial: "messages/message", locals: { message: self }
  end

  def broadcast_conversation_previews
    conversation.users.each do |user|
      stream = [:conversations, user]
      broadcast_remove_to stream, target: dom_id(conversation, :preview)
      broadcast_prepend_to stream,
                              target: dom_id(user, :conversation_list),
                              partial: "conversations/conversation_preview",
                              locals: { conversation:, viewer: user }
    end
  end
end
