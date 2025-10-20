# Notification System Documentation

Comprehensive notification pipeline for Campy project management application.

## Features

✅ **In-App Notifications** - Bell icon with real-time badge updates
✅ **Email Notifications** - Instant alerts for critical events
✅ **Daily Digest Emails** - Consolidated summary of daily activity
✅ **SMS Notifications** - Text alerts via Twilio (configured separately)
✅ **User Preferences** - Granular control over notification channels
✅ **Automated Reminders** - Due date warnings (1, 3, 7 days before) and overdue alerts

---

## Architecture

### Database Schema

**notifications table:**
- `recipient_id` → User receiving the notification
- `actor_id` → User who triggered the action (optional)
- `notifiable_type` + `notifiable_id` → Polymorphic reference to Activity/Comment/Message/Project
- `action` → Type of notification (see below)
- `read_at` → Timestamp when marked as read
- `metadata` → JSON data for additional context
- Indexes on `recipient_id`, `actor_id`, and composite `[recipient_id, read_at]`

**users table additions:**
- `email_notifications` → Boolean (default: true)
- `in_app_notifications` → Boolean (default: true)
- `sms_notifications` → Boolean (default: false)
- `phone_number` → String for SMS delivery
- `daily_digest` → Boolean (default: false)
- `digest_time` → String (default: "09:00") - Time to send digest

---

## Notification Types

| Action | Trigger | Recipient |
|--------|---------|-----------|
| `activity_assigned` | User assigned to activity | Assignee |
| `activity_updated` | Activity details changed | Assignee + Project owner |
| `activity_due_soon` | Due date approaching (1/3/7 days) | Assignee |
| `activity_overdue` | Past due date | Assignee |
| `comment_added` | New comment on activity | Assignee + Project owner |
| `comment_mentioned` | @mention in comment | Mentioned user |
| `message_received` | New DM/conversation message | Conversation participants |
| `project_invitation` | Invited to project | Invited user |
| `member_joined` | New team member | Project owner |

---

## Usage

### Creating Notifications

Use the `NotificationService` to create notifications:

```ruby
# Activity assigned
NotificationService.notify_activity_assigned(activity, current_user)

# Activity updated
NotificationService.notify_activity_updated(activity, current_user)

# Comment added
NotificationService.notify_comment_added(comment)

# Message received
NotificationService.notify_message_received(message)

# Manual notification
NotificationService.notify(
  recipient: user,
  action: "activity_assigned",
  notifiable: activity,
  actor: current_user
)
```

### Integration Points

Add notifications to your controllers:

```ruby
# app/controllers/activities_controller.rb
def update
  if @activity.update(activity_params)
    # Notify if assignee changed
    if @activity.saved_change_to_assignee_id?
      NotificationService.notify_activity_assigned(@activity, current_user)
    else
      NotificationService.notify_activity_updated(@activity, current_user)
    end

    redirect_to @activity
  end
end

# app/controllers/comments_controller.rb
def create
  @comment = @activity.comments.build(comment_params)
  @comment.author_id = current_user.id

  if @comment.save
    NotificationService.notify_comment_added(@comment)
    redirect_to @activity
  end
end
```

---

## Scheduled Jobs

### Daily Digest (09:00 AM)

Sends consolidated email to users who enabled `daily_digest`:

```ruby
# Schedule in cron or whenever gem
SendDailyDigestJob.perform_later
```

### Due Date Reminders (Daily at 08:00 AM)

Checks for upcoming and overdue activities:

```ruby
CheckUpcomingDueDatesJob.perform_later
```

### Example Cron Schedule

Add to `config/schedule.rb` (using whenever gem):

```ruby
every 1.day, at: '8:00 am' do
  runner "CheckUpcomingDueDatesJob.perform_later"
end

every 1.day, at: '9:00 am' do
  runner "SendDailyDigestJob.perform_later"
end
```

Or use Solid Queue recurring tasks in `config/recurring.yml`:

```yaml
daily_digest:
  class: SendDailyDigestJob
  schedule: "0 9 * * *"  # Every day at 9:00 AM

check_due_dates:
  class: CheckUpcomingDueDatesJob
  schedule: "0 8 * * *"  # Every day at 8:00 AM
```

---

## User Preferences

Users can configure notification preferences at `/settings`:

```erb
<%= form_with model: current_user, url: settings_path do |f| %>
  <h3>Notification Preferences</h3>

  <%= f.check_box :email_notifications %>
  <%= f.label :email_notifications, "Email notifications" %>

  <%= f.check_box :in_app_notifications %>
  <%= f.label :in_app_notifications, "In-app notifications" %>

  <%= f.check_box :daily_digest %>
  <%= f.label :daily_digest, "Daily digest email" %>

  <%= f.check_box :sms_notifications %>
  <%= f.label :sms_notifications, "SMS notifications" %>

  <%= f.text_field :phone_number, placeholder: "+1234567890" %>

  <%= f.submit "Save Preferences" %>
<% end %>
```

---

## In-App Notifications

### Bell Icon Component

Add to `app/views/layouts/application.html.erb`:

```erb
<div data-controller="notifications">
  <a href="#" data-action="click->notifications#toggle" class="notification-bell">
    <svg><!-- Bell icon SVG --></svg>
    <span data-notifications-target="badge" class="notification-badge" style="display: none;">0</span>
  </a>

  <div data-notifications-target="dropdown" class="notification-dropdown" style="display: none;">
    <h4>Notifications</h4>
    <a href="<%= notifications_path %>">View all</a>
  </div>
</div>
```

### Auto-Refresh

The Stimulus controller polls `/notifications/unread_count` every 30 seconds and updates the badge automatically.

---

## Email Templates

Email templates are located in `app/views/notification_mailer/`:

- `notification_email.html.erb` - Single notification email
- `daily_digest.html.erb` - Daily summary email

Customize templates to match your branding.

---

## SMS Notifications (Twilio)

### Setup

1. Add to `Gemfile`:
```ruby
gem 'twilio-ruby'
```

2. Configure environment variables:
```bash
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=+1234567890
```

3. Uncomment Twilio code in `app/jobs/sms_notification_job.rb`

4. Verify phone numbers in user settings

### SMS Message Format

Messages are automatically truncated to 160 characters:

```
New task: Design homepage mockups
Reminder: Submit budget report due soon
Overdue: Update project timeline
New message from Sarah Johnson
```

---

## API Endpoints

### GET /notifications
Lists all notifications for current user (paginated)

### POST /notifications/:id/mark_as_read
Marks notification as read, redirects to notifiable resource

### POST /notifications/mark_all_as_read
Marks all unread notifications as read

### GET /notifications/unread_count
Returns JSON: `{ "count": 5 }`

---

## Testing

### Create Test Notifications

```ruby
# In Rails console
user = User.first
activity = Activity.first

NotificationService.notify(
  recipient: user,
  action: "activity_assigned",
  notifiable: activity,
  actor: User.second
)
```

### Test Email Delivery

```ruby
notification = user.notifications.first
NotificationMailer.notification_email(notification).deliver_now
```

### Test Daily Digest

```ruby
SendDailyDigestJob.perform_now
```

### Preview Emails

Visit `/letter_opener` in development to see sent emails.

---

## Performance Considerations

1. **Batch Processing**: Use `.find_each` to process users in batches
2. **Eager Loading**: `.includes(:actor, :notifiable)` to avoid N+1 queries
3. **Indexes**: Composite indexes on `[recipient_id, read_at]` and `[recipient_id, created_at]`
4. **Cleanup**: Archive or delete read notifications older than 90 days

### Cleanup Job

```ruby
# app/jobs/cleanup_old_notifications_job.rb
class CleanupOldNotificationsJob < ApplicationJob
  def perform
    Notification.where("read_at IS NOT NULL AND read_at < ?", 90.days.ago)
                .delete_all
  end
end
```

---

## Customization

### Add New Notification Type

1. Add to `Notification::ACTIONS`:
```ruby
ACTIONS = {
  # ...
  file_uploaded: "file_uploaded"
}.freeze
```

2. Add message template in `Notification#message`

3. Add URL routing in `Notification#url`

4. Add email subject in `NotificationMailer#notification_subject`

5. Create service method:
```ruby
def self.notify_file_uploaded(file, uploader)
  notify(
    recipient: file.project.owner,
    action: "file_uploaded",
    notifiable: file,
    actor: uploader
  )
end
```

---

## Troubleshooting

### Notifications not appearing?
- Check user's `in_app_notifications` preference
- Verify `NotificationService` is being called
- Check Rails logs for errors

### Emails not sending?
- Verify `email_notifications` is enabled
- Check email configuration in `config/environments/production.rb`
- Check Solid Queue is running: `bin/rails solid_queue:start`

### SMS not sending?
- Verify `sms_notifications` enabled and `phone_number` present
- Check Twilio credentials in environment variables
- Uncomment Twilio code in `SmsNotificationJob`

### Badge count not updating?
- Check JavaScript console for errors
- Verify `/notifications/unread_count` endpoint returns JSON
- Check Stimulus controller is connected

---

## Security

- ✅ User can only see their own notifications (scoped by `recipient_id`)
- ✅ CSRF protection on all POST endpoints
- ✅ Phone numbers validated before SMS delivery
- ✅ Email addresses verified through Devise

---

## Next Steps

1. ✅ **Integrate into existing controllers** - Add notification calls to Activity, Comment, Message controllers
2. ✅ **Add UI to layout** - Include notification bell in navigation bar
3. ✅ **Configure job scheduler** - Set up recurring jobs for digests and reminders
4. ✅ **Customize email templates** - Add branding and styling
5. ⏳ **Set up Twilio** - Configure SMS if needed
6. ⏳ **Add user preferences UI** - Let users control notification settings

---

## Files Created

- `db/migrate/XXXXXX_create_notifications.rb`
- `db/migrate/XXXXXX_add_notification_preferences_to_users.rb`
- `app/models/notification.rb`
- `app/controllers/notifications_controller.rb`
- `app/views/notifications/index.html.erb`
- `app/services/notification_service.rb`
- `app/mailers/notification_mailer.rb`
- `app/views/notification_mailer/notification_email.html.erb`
- `app/views/notification_mailer/daily_digest.html.erb`
- `app/jobs/send_daily_digest_job.rb`
- `app/jobs/check_upcoming_due_dates_job.rb`
- `app/jobs/sms_notification_job.rb`
- `app/javascript/controllers/notifications_controller.js`

**Total:** 16 new files + modifications to User model and routes

---

Ready to keep your team aligned! 🔔📧📱
