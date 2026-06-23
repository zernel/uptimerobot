set :output, "#{path}/log/cron.log"
set :environment, ENV.fetch("RAILS_ENV", "development")

every 1.minute do
  runner "MonitorSchedulerJob.perform_later"
end

every 1.day, at: '3:00 am' do
  runner "DataCleanupJob.perform_later"
end

every 1.hour do
  runner "ResponseTimeAggregationJob.perform_later"
end
