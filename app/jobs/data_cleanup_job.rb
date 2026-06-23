class DataCleanupJob < ApplicationJob
  queue_as :maintenance

  def perform
    cleanup_check_results
    cleanup_notification_logs
    cleanup_response_time_stats
  end

  private

  def cleanup_check_results
    CheckResult.where('created_at < ?', 7.days.ago).delete_all

    ResponseTimeStat.where(period_type: 'hourly')
                    .where('period_start < ?', 30.days.ago)
                    .delete_all

    ResponseTimeStat.where(period_type: 'daily')
                    .where('period_start < ?', 1.year.ago)
                    .delete_all
  end

  def cleanup_notification_logs
    NotificationLog.where('created_at < ?', 90.days.ago).delete_all
  end

  def cleanup_response_time_stats
  end
end
