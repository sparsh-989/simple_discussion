class SimpleDiscussion::ForumThreadNotificationJob < ApplicationJob
  include SimpleDiscussion::Engine.routes.url_helpers

  def perform(forum_thread)
    send_emails(forum_thread) if SimpleDiscussion.send_email_notifications
    send_webhook(forum_thread) if SimpleDiscussion.send_slack_notifications
  end

  def send_emails(forum_thread)
    forum_thread.notify_users.each do |user|
      SimpleDiscussion::UserMailer.new_thread(forum_thread, user).deliver_later
    end
  end

  def send_webhook(forum_thread)
    slack_webhook_url = "https://hooks.slack.com/services/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"
    return if slack_webhook_url.blank?

    forum_post = forum_thread.forum_posts.first
    payload = {
      fallback: "A new discussion was started: <#{forum_thread_url(forum_thread, anchor: ActionView::RecordIdentifier.dom_id(forum_post))}|#{forum_thread.title}>",
      pretext: "A new discussion was started: <#{forum_thread_url(forum_thread, anchor: ActionView::RecordIdentifier.dom_id(forum_post))}|#{forum_thread.title}>",
      fields: [
        {
          title: "Thread",
          value: forum_thread.title,
          short: true
        },
        {
          title: "Posted By",
          value: forum_post.user.name,
          short: true
        }
      ],
      ts: forum_post.created_at.to_i
    }

    SimpleDiscussion::Slack.new(slack_webhook_url).post(payload)
  end
end
