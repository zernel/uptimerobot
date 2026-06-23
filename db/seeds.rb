puts "Seeding database..."

admin = User.find_or_create_by!(email: 'admin@example.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.admin = true
end
puts "Created admin user: admin@example.com / password123"

# Create monitor groups
web_group = MonitorGroup.find_or_create_by!(name: 'Web Services') do |g|
  g.description = 'Web applications and APIs'
  g.sort_order = 1
end

api_group = MonitorGroup.find_or_create_by!(name: 'API Services') do |g|
  g.description = 'Backend APIs'
  g.sort_order = 2
end

infrastructure_group = MonitorGroup.find_or_create_by!(name: 'Infrastructure') do |g|
  g.description = 'Servers and infrastructure'
  g.sort_order = 3
end
puts "Created monitor groups"

# Create tags
critical_tag = Tag.find_or_create_by!(name: 'Critical') { |t| t.color = '#dc2626' }
production_tag = Tag.find_or_create_by!(name: 'Production') { |t| t.color = '#2563eb' }
staging_tag = Tag.find_or_create_by!(name: 'Staging') { |t| t.color = '#d97706' }
puts "Created tags"

# Create sample monitors
monitors_data = [
  {
    name: 'Google',
    monitor_type: 'http',
    url: 'https://www.google.com',
    interval: 300,
    monitor_group: web_group,
    tags: [production_tag, critical_tag]
  },
  {
    name: 'GitHub',
    monitor_type: 'http',
    url: 'https://github.com',
    interval: 300,
    monitor_group: web_group,
    tags: [production_tag]
  },
  {
    name: 'Example API',
    monitor_type: 'api',
    url: 'https://jsonplaceholder.typicode.com/posts/1',
    http_method: 'GET',
    api_assertions: [{ 'path' => 'userId', 'operator' => 'exists', 'value' => '' }],
    interval: 600,
    monitor_group: api_group,
    tags: [production_tag]
  },
  {
    name: 'Google DNS',
    monitor_type: 'ping',
    hostname: '8.8.8.8',
    interval: 300,
    monitor_group: infrastructure_group,
    tags: [critical_tag]
  },
  {
    name: 'Cloudflare DNS',
    monitor_type: 'dns',
    hostname: 'example.com',
    dns_record_type: 'A',
    interval: 600,
    monitor_group: infrastructure_group,
    tags: [production_tag]
  },
  {
    name: 'Example SSL',
    monitor_type: 'ssl',
    hostname: 'example.com',
    alert_days_before: 30,
    interval: 86400,
    monitor_group: infrastructure_group,
    tags: [production_tag]
  }
]

monitors_data.each do |data|
  tags = data.delete(:tags)
  monitor = SiteMonitor.find_or_create_by!(name: data[:name]) do |m|
    m.assign_attributes(data)
    m.status = 'pending'
  end
  monitor.tags = tags if tags
  puts "Created monitor: #{monitor.name}"
end

# Create notification channels
email_channel = NotificationChannel.find_or_create_by!(name: 'Admin Email') do |c|
  c.channel_type = 'email'
  c.config = { address: 'admin@example.com' }
end
puts "Created notification channel: Admin Email"

# Create status page
status_page = StatusPage.find_or_create_by!(name: 'Service Status') do |sp|
  sp.slug = 'status'
  sp.published = true
  sp.theme_color = '#1F2937'
  sp.header_bg_color = '#1F2937'
  sp.layout = 'wide'
  sp.show_uptime_percentage = true
  sp.show_response_time_graph = true
end
status_page.monitors = SiteMonitor.all
puts "Created status page: Service Status"

# Create sample maintenance window
MaintenanceWindow.find_or_create_by!(name: 'Scheduled Maintenance') do |mw|
  mw.description = 'Weekly server maintenance'
  mw.starts_at = 1.day.from_now.beginning_of_day + 2.hours
  mw.ends_at = 1.day.from_now.beginning_of_day + 4.hours
  mw.recurrence = 'weekly'
  mw.monitor_ids = []
end
puts "Created maintenance window"

puts "\nSeeding complete!"
puts "Login with: admin@example.com / password123"
puts "Visit http://localhost:3000 to access the dashboard"
puts "Visit http://localhost:3000/status/status for the public status page"
