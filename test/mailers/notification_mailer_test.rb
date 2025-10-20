require "test_helper"

class NotificationMailerTest < ActionMailer::TestCase
  test "notification_email" do
    mail = NotificationMailer.notification_email
    assert_equal "Notification email", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "daily_digest" do
    mail = NotificationMailer.daily_digest
    assert_equal "Daily digest", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
