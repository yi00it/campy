require "csv"

class ActivitiesImportsController < ApplicationController
  before_action :set_project

  def new
    @import = {} # Placeholder for form
  end

  def create
    Rails.logger.info "=== Import Create Action ==="
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "File present: #{params[:file].present?}"
    Rails.logger.info "Preview: #{params[:preview]}"

    unless params[:file].present?
      redirect_to new_project_activities_import_path(@project), alert: "Please select a file to import"
      return
    end

    importer = ActivitiesImporter.new(@project, params[:file])

    if params[:preview]
      @preview_activities = importer.preview
      @errors = importer.errors
      @uploaded_file = params[:file]

      if @errors.any?
        flash.now[:alert] = "Errors found in file"
        render :new
      else
        # Store file path in session for later import
        session[:import_file_path] = params[:file].tempfile.path
        session[:import_file_name] = params[:file].original_filename
        render :preview
      end
    elsif params[:confirm] && session[:import_file_path]
      # Recreate the file upload from session
      tempfile = File.open(session[:import_file_path])
      uploaded_file = ActionDispatch::Http::UploadedFile.new(
        tempfile: tempfile,
        filename: session[:import_file_name],
        type: params[:file]&.content_type || "text/csv"
      )

      importer = ActivitiesImporter.new(@project, uploaded_file)

      if importer.import
        session.delete(:import_file_path)
        session.delete(:import_file_name)
        redirect_to @project,
                   notice: "Successfully imported #{importer.imported_count} activities"
      else
        flash.now[:alert] = "Import failed with errors"
        @errors = importer.errors
        session.delete(:import_file_path)
        session.delete(:import_file_name)
        render :new
      end
    else
      # Direct import without preview
      if importer.import
        redirect_to @project,
                   notice: "Successfully imported #{importer.imported_count} activities"
      else
        flash.now[:alert] = "Import failed with errors"
        @errors = importer.errors
        render :new
      end
    end
  end

  def template
    csv_data = CSV.generate(headers: true) do |csv|
      # Header row
      headers = ["Activity Name", "Start Date", "Finish Date", "Duration (days)",
                 "Assignee Email", "Discipline", "Zone", "Description", "Status"]
      csv << headers

      # Example rows
      csv << [
        "Design Phase",
        Date.current.to_s,
        (Date.current + 14.days).to_s,
        "14",
        "user@example.com",
        "Engineering",
        "Zone A",
        "Complete the design phase",
        "Not Started"
      ]

      csv << [
        "Development Phase",
        (Date.current + 15.days).to_s,
        (Date.current + 45.days).to_s,
        "30",
        "",
        "Development",
        "Zone B",
        "Implement the solution",
        "Not Started"
      ]

      csv << [
        "Testing Phase",
        (Date.current + 46.days).to_s,
        (Date.current + 60.days).to_s,
        "15",
        "",
        "QA",
        "Zone A",
        "Test the implementation",
        "Not Started"
      ]
    end

    send_data csv_data,
              filename: "activities_import_template_#{Date.current}.csv",
              type: "text/csv",
              disposition: "attachment"
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
    unless @project.owner_id == current_user.id
      redirect_to projects_path, alert: "Not allowed."
    end
  end
end
