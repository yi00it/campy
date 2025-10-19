class MessagesChannel < ApplicationCable::Channel
  def subscribed
    conversation = Conversation.for_user(current_user).find(params[:conversation_id])
    stream_for conversation
  end

  def unsubscribed
    stop_all_streams
  end
end
