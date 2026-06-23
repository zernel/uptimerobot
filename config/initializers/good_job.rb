# frozen_string_literal: true

Rails.application.configure do
  config.active_job.queue_adapter = :good_job

  config.good_job = {
    # Job preservation for debugging
    preserve_job_records: true,
    retry_on_unhandled_error: false,

    # Error reporting
    on_thread_error: ->(exception) { Rails.error.report(exception) },

    # Execution mode: :async for development, :external for production
    execution_mode: Rails.env.production? ? :external : :async,

    # Queue configuration
    queues: '*',
    max_threads: Rails.env.production? ? 10 : 2,

    # Polling interval (seconds)
    poll_interval: 30,

    # Graceful shutdown timeout
    shutdown_timeout: 25,

    # Enable cron scheduling
    enable_cron: true,
    cron_graceful_restart_period: 5.minutes,

    # Cron jobs for monitoring
    cron: {
      monitor_scheduler: {
        cron: '* * * * *',  # Every minute
        class: 'MonitorSchedulerJob',
        description: 'Schedule monitor checks based on intervals'
      },
      data_cleanup: {
        cron: '0 3 * * *',  # 3 AM daily
        class: 'DataCleanupJob',
        description: 'Clean up old check results and notification logs'
      },
      response_time_aggregation: {
        cron: '0 * * * *',  # Every hour
        class: 'ResponseTimeAggregationJob',
        description: 'Aggregate response time statistics'
      }
    },

    # Dashboard locale
    dashboard_default_locale: :en
  }
end
