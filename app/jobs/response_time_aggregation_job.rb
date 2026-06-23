class ResponseTimeAggregationJob < ApplicationJob
  queue_as :maintenance

  def perform
    aggregate_hourly_stats
  end

  private

  def aggregate_hourly_stats
    one_hour_ago = 1.hour.ago.beginning_of_hour

    SiteMonitor.active.find_each do |monitor|
      results = monitor.check_results
                      .where('checked_at >= ? AND checked_at < ?', one_hour_ago, one_hour_ago + 1.hour)
                      .where.not(response_time: nil)

      next if results.empty?

      response_times = results.pluck(:response_time).sort

      ResponseTimeStat.create!(
        monitor: monitor,
        period_type: 'hourly',
        period_start: one_hour_ago,
        avg_response_time: (response_times.sum.to_f / response_times.length).round,
        min_response_time: response_times.first,
        max_response_time: response_times.last,
        p95_response_time: response_times[(response_times.length * 0.95).floor],
        check_count: response_times.length
      )
    end
  end
end
