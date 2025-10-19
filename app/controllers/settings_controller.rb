class SettingsController < ApplicationController
  def show
    @user = current_user
  end

  def update
    @user = current_user
    filtered_params = settings_params.to_h.with_indifferent_access
    remove_avatar = ActiveModel::Type::Boolean.new.cast(filtered_params.delete(:remove_avatar))
    @user.avatar.purge if remove_avatar && @user.avatar.attached?

    if password_params_present?(filtered_params.symbolize_keys)
      filtered_params.delete(:preferred_theme) if filtered_params[:preferred_theme].blank?
      update_with_password(filtered_params)
    else
      filtered_params = filtered_params.except(:password, :password_confirmation, :current_password)
      update_without_password(filtered_params)
    end
  end

  private

  def update_with_password(filtered_params)
    if filtered_params[:current_password].blank?
      @user.errors.add(:current_password, "can't be blank")
      render :show, status: :unprocessable_entity
      return
    end

    if @user.update_with_password(filtered_params)
      bypass_sign_in(@user)
      redirect_to settings_path, notice: "Settings updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update_without_password(filtered_params)
    if @user.update(filtered_params)
      redirect_to settings_path, notice: "Settings updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def settings_params
    params.require(:user).permit(
      :username,
      :preferred_theme,
      :avatar,
      :remove_avatar,
      :password,
      :password_confirmation,
      :current_password
    )
  end

  def password_params_present?(filtered_params)
    filtered_params[:password].present? || filtered_params[:password_confirmation].present?
  end
end
