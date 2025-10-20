require "roo"

class ActivitiesImporter
  attr_reader :project, :file, :errors, :imported_count, :skipped_count

  REQUIRED_HEADERS = ["Activity Name", "Start Date", "Finish Date"].freeze
  OPTIONAL_HEADERS = ["Duration (days)", "Assignee Email", "Discipline", "Zone", "Description", "Status"].freeze
  ALL_HEADERS = (REQUIRED_HEADERS + OPTIONAL_HEADERS).freeze

  def initialize(project, file)
    @project = project
    @file = file
    @errors = []
    @imported_count = 0
    @skipped_count = 0
  end

  def import
    spreadsheet = open_spreadsheet
    return false unless spreadsheet

    headers = spreadsheet.row(1)
    validate_headers(headers)
    return false if @errors.any?

    (2..spreadsheet.last_row).each do |row_num|
      import_row(spreadsheet.row(row_num), headers, row_num)
    end

    @errors.empty?
  end

  def preview
    spreadsheet = open_spreadsheet
    return [] unless spreadsheet

    headers = spreadsheet.row(1)
    validate_headers(headers)
    return [] if @errors.any?

    activities = []
    (2..[spreadsheet.last_row, 11].min).each do |row_num| # Preview first 10 rows
      row_data = spreadsheet.row(row_num)
      activities << build_activity_hash(row_data, headers, row_num)
    end

    activities
  end

  private

  def open_spreadsheet
    case File.extname(file.original_filename)
    when ".xlsx"
      Roo::Excelx.new(file.path)
    when ".xls"
      Roo::Excel.new(file.path)
    when ".csv"
      Roo::CSV.new(file.path)
    else
      @errors << "Unknown file type: #{file.original_filename}. Please upload .xlsx, .xls, or .csv"
      nil
    end
  rescue => e
    @errors << "Error opening file: #{e.message}"
    nil
  end

  def validate_headers(headers)
    missing_headers = REQUIRED_HEADERS - headers
    if missing_headers.any?
      @errors << "Missing required columns: #{missing_headers.join(', ')}"
    end
  end

  def import_row(row_data, headers, row_num)
    activity_hash = build_activity_hash(row_data, headers, row_num)
    return if activity_hash[:skip]

    activity = project.activities.new(activity_hash[:attributes])

    if activity.save
      @imported_count += 1
    else
      @errors << "Row #{row_num}: #{activity.errors.full_messages.join(', ')}"
      @skipped_count += 1
    end
  rescue => e
    @errors << "Row #{row_num}: #{e.message}"
    @skipped_count += 1
  end

  def build_activity_hash(row_data, headers, row_num)
    data = Hash[headers.zip(row_data)]

    # Skip empty rows
    if data["Activity Name"].blank?
      return { skip: true }
    end

    attributes = {
      title: data["Activity Name"],
      description: data["Description"],
      start_on: parse_date(data["Start Date"]),
      due_on: parse_date(data["Finish Date"]),
      duration_days: data["Duration (days)"]&.to_i,
      is_done: parse_status(data["Status"])
    }

    # Find assignee by email
    if data["Assignee Email"].present?
      assignee = project.assignable_members.find { |member| member.email == data["Assignee Email"] }
      if assignee
        attributes[:assignee_id] = assignee.id
      else
        @errors << "Row #{row_num}: Assignee '#{data["Assignee Email"]}' not found in project team"
      end
    end

    # Find or create discipline
    if data["Discipline"].present?
      discipline = Discipline.find_or_create_by(name: data["Discipline"])
      attributes[:discipline_id] = discipline.id
    end

    # Find or create zone
    if data["Zone"].present?
      zone = Zone.find_or_create_by(name: data["Zone"])
      attributes[:zone_id] = zone.id
    end

    { attributes: attributes, skip: false, row_data: data }
  end

  def parse_date(date_value)
    return nil if date_value.blank?

    # Handle various date formats
    case date_value
    when Date, Time, DateTime
      date_value.to_date
    when Numeric # Excel serial date
      Date.new(1899, 12, 30) + date_value.to_i
    when String
      Date.parse(date_value) rescue nil
    else
      nil
    end
  end

  def parse_status(status_value)
    return false if status_value.blank?

    status_value.to_s.downcase.in?(%w[complete completed done yes true 1])
  end

  def self.generate_template
    require "csv"

    CSV.generate(headers: true) do |csv|
      # Header row
      csv << ALL_HEADERS

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
    end
  end
end
