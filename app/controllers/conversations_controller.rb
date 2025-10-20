class ConversationsController < ApplicationController
  def index
    @conversations = Conversation.for_user(current_user)
                                 .includes(:users, :messages)
                                 .order(updated_at: :desc)
    @users = current_user.teammates.order(Arel.sql("LOWER(COALESCE(users.username, users.email))"))
  end

  def show
    @conversation = Conversation.for_user(current_user).includes(messages: :user, users: []).find(params[:id])
    @other_users = @conversation.users.where.not(id: current_user.id)

    unless @other_users.all? { |user| current_user.teammate_ids.include?(user.id) }
      redirect_to conversations_path, alert: "You can only message teammates." and return
    end

    @users = @conversation.users
    @messages = @conversation.messages.order(created_at: :asc)
    @message = Message.new
    @can_message = @other_users.all? { |user| can_message_user?(user) }
  end

  def create
    target_user = permitted_user
    unless target_user
      redirect_to conversations_path, alert: "You can only start conversations with teammates." and return
    end

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

  def permitted_user
    user_id = params.require(:conversation)[:user_id]
    return if user_id.blank?

    current_user.teammates.find_by(id: user_id)
  end
end
