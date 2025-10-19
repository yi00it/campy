class ZonesController < ApplicationController
  before_action :set_zone, only: [:edit, :update, :destroy]

  def index
    @zones = Zone.order(:name)
    @zone = Zone.new
  end

  def create
    @zone = Zone.new(zone_params)
    if @zone.save
      redirect_to zones_path, notice: "Zone added."
    else
      @zones = Zone.order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @zone.update(zone_params)
      redirect_to zones_path, notice: "Zone updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @zone.destroy
    redirect_to zones_path, notice: "Zone removed."
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to zones_path, alert: "Cannot delete a zone with activities."
  end

  private

  def set_zone
    @zone = Zone.find(params[:id])
  end

  def zone_params
    params.require(:zone).permit(:name)
  end
end
