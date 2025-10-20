class CalendarEventsController < ApplicationController
  before_action :set_event, only: [:edit, :update, :destroy]

  def new
    @calendar_event = current_user.calendar_events.new(suggested_params)
  end

  def create
    @calendar_event = current_user.calendar_events.new(event_params)
    if @calendar_event.save
      redirect_to calendar_path(month: @calendar_event.start_at.to_date), notice: "Event added to your calendar."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @calendar_event.update(event_params)
      redirect_to calendar_path(month: @calendar_event.start_at.to_date), notice: "Event updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    date = @calendar_event.start_at.to_date
    @calendar_event.destroy
    redirect_to calendar_path(month: date), notice: "Event removed."
  end

  private

  def set_event
    @calendar_event = current_user.calendar_events.find(params[:id])
  end

  def suggested_params
    return {} unless params[:start_at]

    { start_at: params[:start_at], end_at: params[:start_at], all_day: true }
  end

  def event_params
    params.require(:calendar_event).permit(:title, :description, :start_at, :end_at, :event_type, :location, :all_day)
  end
end
