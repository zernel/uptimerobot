# frozen_string_literal: true

if Rails.env.test?
  Rails.application.config.active_job.queue_adapter = :test
else
  Rails.application.configure do
    config.active_job.queue_adapter = :good_job

    config.good_job = {
      preserve_job_records: true,
      retry_on_unhandled_error: false,
      on_thread_error: ->(exception) { Rails.error.report(exception) },
      execution_mode: Rails.env.production? ? :external : :async,
      queues: '*',
      max_threads: Rails.env.production? ? 10 : 2,
      poll_interval: 30,
      shutdown_timeout: 25,
      enable_cron: true,
      cron_graceful_restart_period: 5.minutes,
      cron: {
        monitor_scheduler: {
          cron: '* * * * *',
          class: 'MonitorSchedulerJob',
          description: 'Schedule monitor checks based on intervals'
        },
        data_cleanup: {
          cron: '0 3 * * *',
          class: 'DataCleanupJob',
          description: 'Clean up old check results and notification logs'
        },
        response_time_aggregation: {
          cron: '0 * * * *',
          class: 'ResponseTimeAggregationJob',
          description: 'Aggregate response time statistics'
        }
      },
      dashboard_default_locale: :en
    }
  end
end
