class MessagesController < ApplicationController
  before_action :set_conversation

  def create
    @message = @conversation.messages.build(message_params.merge(user: current_user))

    if @message.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to conversation_path(@conversation) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@conversation, :form), partial: "messages/form", locals: { conversation: @conversation, message: @message }) }
        format.html do
          @messages = @conversation.messages.order(created_at: :asc)
          render "conversations/show", status: :unprocessable_entity
        end
      end
    end
  end

  private

  def set_conversation
    @conversation = Conversation.for_user(current_user).find(params[:conversation_id])
  end

  def message_params
    params.require(:message).permit(:body)
  end
end
