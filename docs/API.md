# API Reference

## Overview

The application provides internal REST endpoints for the web UI. There is no public REST API.

## Authentication

All endpoints require authentication via Devise session (cookie-based), except:
- Public status pages (`/status/:slug`)
- Heartbeat endpoint (`/heartbeat/:token`)
- Health check (`/up`)

## Endpoints

### Dashboard

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Dashboard with monitor stats |

### Monitors

| Method | Path | Description |
|--------|------|-------------|
| GET | `/monitors` | List all monitors |
| POST | `/monitors` | Create monitor |
| GET | `/monitors/:id` | Show monitor details |
| PATCH | `/monitors/:id` | Update monitor |
| DELETE | `/monitors/:id` | Delete monitor |
| POST | `/monitors/:id/pause` | Pause monitor |
| POST | `/monitors/:id/resume` | Resume monitor |
| POST | `/monitors/:id/reset` | Reset monitor status |

#### Monitor Parameters

```ruby
{
  monitor: {
    name: "My Website",
    monitor_type: "http",        # http, keyword, ping, port, heartbeat, ssl, domain, dns, api
    url: "https://example.com",  # For HTTP/keyword/API monitors
    hostname: "example.com",     # For ping/port/SSL/domain/DNS monitors
    port: 443,                   # For port monitors
    http_method: "GET",          # GET, POST, PUT, DELETE
    http_headers: {},            # Custom HTTP headers
    http_body: "",               # Request body
    follow_redirects: true,
    verify_ssl: true,
    keyword: "success",          # For keyword monitors
    keyword_type: "exists",      # exists, not_exists
    api_assertions: [],          # For API monitors
    heartbeat_interval: 3600,    # For heartbeat monitors (seconds)
    alert_days_before: 30,       # For SSL/domain monitors
    dns_record_type: "A",        # A, AAAA, CNAME, MX, TXT
    dns_expected_value: "",      # Expected DNS value
    interval: 300,               # Check interval (seconds)
    timeout: 30,                 # Check timeout (seconds)
    retries: 2,
    alert_threshold: 1,          # Failures before alert
    alert_delay: 0,              # Delay before alert (seconds)
    monitor_group_id: 1,
    description: "",
    paused: false,
    tag_ids: [1, 2]
  }
}
```

### Check Results

| Method | Path | Description |
|--------|------|-------------|
| GET | `/monitors/:monitor_id/check_results` | List check results |

### Incidents

| Method | Path | Description |
|--------|------|-------------|
| GET | `/incidents` | List all incidents |
| GET | `/incidents/:id` | Show incident details |
| GET | `/monitors/:monitor_id/incidents` | List monitor incidents |

#### Incident Parameters

```ruby
{
  incident_comment: {
    content: "Root cause identified..."
  }
}
```

### Monitor Groups

| Method | Path | Description |
|--------|------|-------------|
| GET | `/monitor_groups` | List groups |
| POST | `/monitor_groups` | Create group |
| GET | `/monitor_groups/:id` | Show group |
| PATCH | `/monitor_groups/:id` | Update group |
| DELETE | `/monitor_groups/:id` | Delete group |

### Tags

| Method | Path | Description |
|--------|------|-------------|
| GET | `/tags` | List tags |
| POST | `/tags` | Create tag |
| GET | `/tags/:id` | Show tag |
| PATCH | `/tags/:id` | Update tag |
| DELETE | `/tags/:id` | Delete tag |

### Notification Channels

| Method | Path | Description |
|--------|------|-------------|
| GET | `/notification_channels` | List channels |
| POST | `/notification_channels` | Create channel |
| GET | `/notification_channels/:id` | Show channel |
| PATCH | `/notification_channels/:id` | Update channel |
| DELETE | `/notification_channels/:id` | Delete channel |

#### Channel Parameters

```ruby
{
  notification_channel: {
    name: "Slack Alerts",
    channel_type: "slack",       # email, slack, mattermost, feishu
    enabled: true,
    config: {
      webhook_url: "https://hooks.slack.com/...",
      address: "admin@example.com",  # For email
      channel: "#alerts"             # For Mattermost
    }
  }
}
```

### Status Pages

| Method | Path | Description |
|--------|------|-------------|
| GET | `/status_pages` | List pages |
| POST | `/status_pages` | Create page |
| GET | `/status_pages/:id` | Show page |
| PATCH | `/status_pages/:id` | Update page |
| DELETE | `/status_pages/:id` | Delete page |
| GET | `/status_pages/:id/preview` | Preview page |

#### Status Page Parameters

```ruby
{
  status_page: {
    name: "Service Status",
    slug: "status",
    logo_url: "",
    favicon_url: "",
    theme_color: "#1F2937",
    header_bg_color: "#1F2937",
    layout: "wide",              # wide, compact
    show_uptime_percentage: true,
    show_response_time_graph: true,
    show_monitor_url: false,
    show_paused_monitors: false,
    sort_by: "status",           # name, status
    password: "",                # Optional password
    google_analytics_id: "",
    noindex: false,
    published: true,
    monitor_ids: [1, 2, 3]
  }
}
```

### Announcements

| Method | Path | Description |
|--------|------|-------------|
| GET | `/status_pages/:status_page_id/announcements` | List announcements |
| POST | `/status_pages/:status_page_id/announcements` | Create announcement |
| GET | `/status_pages/:status_page_id/announcements/:id` | Show announcement |
| PATCH | `/status_pages/:status_page_id/announcements/:id` | Update announcement |
| DELETE | `/status_pages/:status_page_id/announcements/:id` | Delete announcement |

### Maintenance Windows

| Method | Path | Description |
|--------|------|-------------|
| GET | `/maintenance_windows` | List windows |
| POST | `/maintenance_windows` | Create window |
| GET | `/maintenance_windows/:id` | Show window |
| PATCH | `/maintenance_windows/:id` | Update window |
| DELETE | `/maintenance_windows/:id` | Delete window |

#### Maintenance Window Parameters

```ruby
{
  maintenance_window: {
    name: "Weekly Maintenance",
    description: "Server updates",
    starts_at: "2026-06-24T02:00:00Z",
    ends_at: "2026-06-24T04:00:00Z",
    recurrence: "weekly",        # none, daily, weekly, monthly
    recurrence_end_at: "2026-12-31T00:00:00Z",
    monitor_ids: [1, 2]          # Empty = all monitors
  }
}
```

### Public Endpoints

#### Heartbeat

```
GET /heartbeat/:token
```

Response:
```json
{ "status": "ok" }
```

#### Public Status Page

```
GET /status/:slug
```

Returns HTML status page.

#### Health Check

```
GET /up
```

Returns 200 OK if application is running.

## GoodJob Dashboard

Accessible at `/good_job` (admin only). Shows:
- Job queue status
- Failed jobs
- Cron schedules
- Job execution history
