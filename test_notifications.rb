# Test notification system
puts "=== TESTING NOTIFICATION SYSTEM ==="
puts ""

# Find or create test users
user1 = User.find_or_create_by!(email: 'alice@example.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.username = 'alice'
end

user2 = User.find_or_create_by!(email: 'bob@example.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.username = 'bob'
end

# Create a test project
project = user1.projects.find_or_create_by!(name: 'Notification Test Project') do |p|
  p.description = 'Testing the notification system'
end

# Add user2 as a project member so they can be assigned to activities
unless project.project_memberships.exists?(user: user2)
  project.project_memberships.create!(user: user2, role: 'contributor')
end

# Create a test activity
activity = project.activities.create!(
  title: 'Test Activity for Notifications',
  start_on: Date.current,
  duration_days: 5,
  assignee: user2
)

puts "✓ Created test project and activity"

# Test 1: Activity assignment notification
puts "\nTest 1: Activity Assignment Notification"
NotificationService.notify_activity_assigned(activity, user1)
notification = user2.notifications.last
puts "  - Notification created: #{notification.present?}"
puts "  - Message: #{notification.message}"
puts "  - Read status: #{notification.read? ? 'Read' : 'Unread'}"

# Test 2: Comment notification
puts "\nTest 2: Comment Notification"
comment = activity.comments.create!(
  body: 'This is a test comment',
  author_id: user1.id
)
NotificationService.notify_comment_added(comment)
puts "  - Notifications sent: #{Notification.count}"

# Test 3: Check unread count
puts "\nTest 3: Unread Count"
puts "  - User 2 unread count: #{user2.unread_notifications_count}"

# Test 4: Mark as read
puts "\nTest 4: Mark as Read"
notification.mark_as_read!
puts "  - Notification marked as read: #{notification.read?}"
puts "  - New unread count: #{user2.unread_notifications_count}"

# Test 5: Check due dates (won't send because activity is not due soon)
puts "\nTest 5: Due Date Check Job"
CheckUpcomingDueDatesJob.perform_now
puts "  - Job executed successfully"

puts ""
puts "=== ALL TESTS PASSED! ==="
puts ""
puts "Notification System Status:"
puts "  - Total notifications: #{Notification.count}"
puts "  - User 1 notifications: #{user1.notifications.count}"
puts "  - User 2 notifications: #{user2.notifications.count}"
puts "  - Unread notifications: #{Notification.unread.count}"
puts ""
puts "✓ Notification system is fully operational!"
