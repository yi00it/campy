module ApplicationHelper
  def avatar_for(user, size: 36)
    return "" unless user

    if user.avatar.attached?
      image = user.avatar
      image = image.variant(resize_to_fill: [size, size]) if image.variable?
      image_tag image, alt: user.display_name, class: "nav__avatar-img", size: "#{size}x#{size}"
    else
      initials = extract_initials(user.display_name)
      content_tag(:span, initials, class: "nav__avatar-placeholder")
    end
  end

  # Notification helpers
  def notification_date_group(notification)
    return "Today" if notification.created_at.to_date == Date.current
    return "Yesterday" if notification.created_at.to_date == Date.current - 1.day

    notification.created_at.strftime("%B %d, %Y")
  end

  def notification_type_category(action)
    case action
    when "comment_mentioned"
      "mention"
    when "activity_assigned", "activity_updated", "activity_due_soon", "activity_overdue"
      "activity"
    when "project_invitation", "member_joined"
      "project"
    else
      "all"
    end
  end

  def notification_icon_type(action)
    case action
    when "activity_assigned", "activity_updated"
      "task"
    when "activity_due_soon"
      "calendar"
    when "activity_overdue"
      "warning"
    when "comment_added", "comment_mentioned"
      "comment"
    when "message_received"
      "message"
    when "project_invitation"
      "invite"
    when "member_joined"
      "user"
    else
      "default"
    end
  end

  def notification_title(notification)
    case notification.action
    when "activity_assigned"
      "Activity Assigned"
    when "activity_updated"
      "Activity Updated"
    when "activity_due_soon"
      "Due Date Approaching"
    when "activity_overdue"
      "Activity Overdue"
    when "comment_added"
      "New Comment"
    when "comment_mentioned"
      "You Were Mentioned"
    when "message_received"
      "New Message"
    when "project_invitation"
      "Project Invitation"
    when "member_joined"
      "New Member Added"
    else
      "Notification"
    end
  end

  def notification_icon_svg(action)
    case notification_icon_type(action)
    when "task"
      '<svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M9 5H7a2 2 0 00-2 2v8a2 2 0 002 2h6a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h0a2 2 0 002-2M9 5a2 2 0 012-2h0a2 2 0 012 2m-6 9l2 2 4-4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>'.html_safe
    when "calendar"
      '<svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M6 2v2m8-2v2M3 8h14M5 4h10a2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2V6a2 2 0 012-2z" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>'.html_safe
    when "warning"
      '<svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M10 6v4m0 4h.01M19 10a9 9 0 11-18 0 9 9 0 0118 0z" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>'.html_safe
    when "comment"
      '<svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M8 10h.01M12 10h.01M10 14h.01M17 10a7 7 0 11-14 0 7 7 0 0114 0z" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>'.html_safe
    when "message"
      '<svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>'.html_safe
    when "invite"
      '<svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>'.html_safe
    when "user"
      '<svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M16 17v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2m8-10a4 4 0 100-8 4 4 0 000 8z" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>'.html_safe
    else
      '<svg width="20" height="20" viewBox="0 0 20 20" fill="none"><circle cx="10" cy="10" r="8" stroke="currentColor" stroke-width="1.5"/></svg>'.html_safe
    end
  end

  private

  def extract_initials(name)
    return "?" if name.blank?

    name.split(/\s+/).first(2).map { |part| part[0].to_s.upcase }.join.presence || "?"
  end
end
