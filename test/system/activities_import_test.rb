require "application_system_test_case"

class ActivitiesImportTest < ApplicationSystemTestCase
  # System test for the CSV/Excel import workflow
  # Tests the complete user journey for importing activities

  setup do
    # Create a user and sign in
    @user = User.create!(
      email: "import_test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    # Create a project
    @project = @user.projects.create!(
      name: "Import Test Project",
      description: "Testing activity imports"
    )

    # Create test CSV file
    @csv_file = Rails.root.join("tmp", "test_import.csv")
    CSV.open(@csv_file, "w") do |csv|
      csv << ["Activity Name", "Start Date", "Finish Date", "Duration (days)", "Assignee Email", "Discipline", "Zone", "Description", "Status"]
      csv << ["Design Phase", "2025-10-01", "2025-10-14", "14", "", "Engineering", "Zone A", "Complete design", "Not Started"]
      csv << ["Development Phase", "2025-10-15", "2025-11-14", "31", "", "Development", "Zone B", "Build features", "Not Started"]
    end
  end

  teardown do
    # Clean up test file
    File.delete(@csv_file) if File.exist?(@csv_file)
  end

  test "import activities from CSV file" do
    skip "Skipping system test - requires Selenium setup"

    visit root_path

    # Sign in (assuming Devise sign in flow)
    fill_in "Email", with: @user.email
    fill_in "Password", with: "password123"
    click_button "Log in"

    # Navigate to project
    click_link @project.name

    # Navigate to import page
    click_link "Import Activities"

    # Upload CSV file
    attach_file "file", @csv_file
    click_button "Preview"

    # Should show preview
    assert_text "Design Phase"
    assert_text "Development Phase"
    assert_text "Engineering"

    # Confirm import
    click_button "Import"

    # Should show success message
    assert_text "Successfully imported 2 activities"

    # Verify activities were created
    assert_equal 2, @project.activities.count
    assert @project.activities.find_by(title: "Design Phase")
    assert @project.activities.find_by(title: "Development Phase")
  end

  test "validates CSV format before import" do
    skip "Skipping system test - requires Selenium setup"

    # Create invalid CSV (missing required columns)
    invalid_csv = Rails.root.join("tmp", "invalid_import.csv")
    CSV.open(invalid_csv, "w") do |csv|
      csv << ["Wrong Column", "Another Wrong Column"]
      csv << ["Some Data", "More Data"]
    end

    visit root_path
    fill_in "Email", with: @user.email
    fill_in "Password", with: "password123"
    click_button "Log in"

    click_link @project.name
    click_link "Import Activities"

    attach_file "file", invalid_csv
    click_button "Preview"

    # Should show validation error
    assert_text "Missing required columns"

    File.delete(invalid_csv)
  end
end
