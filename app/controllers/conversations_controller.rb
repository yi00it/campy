class ConversationsController < ApplicationController
  def index
    @conversations = Conversation.for_user(current_user).includes(:users).order(updated_at: :desc)
    @users = User.where.not(id: current_user.id).order(:email)
  end

  def show
    @conversation = Conversation.for_user(current_user).includes(messages: :user).find(params[:id])
    @users = @conversation.users
    @messages = @conversation.messages.order(created_at: :asc)
    @message = Message.new
  end

  def create
    target_user = User.find(params.require(:conversation)[:user_id])
    conversation = find_or_create_conversation_with(target_user)
    redirect_to conversation_path(conversation)
  end

  private

  def find_or_create_conversation_with(user)
    conversation = Conversation.between([current_user.id, user.id]).first
    return conversation if conversation

    Conversation.transaction do
      conversation = Conversation.create!
      conversation.conversation_memberships.create!(user: current_user)
      conversation.conversation_memberships.create!(user: user)
      conversation
    end
  end
end
