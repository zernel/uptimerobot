# Database Schema

## Overview

The application uses 18 custom tables plus GoodJob's tables for background job management.

## Entity Relationship

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│ SiteMonitor │──────<│ CheckResult │       │    User     │
│  (monitors) │       │             │       │             │
└─────────────┘       └─────────────┘       └─────────────┘
       │                                           │
       │                                           │
       ▼                                           ▼
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│  Incident   │──────<│   Comment   │       │   ApiKey    │
│             │       │             │       │             │
└─────────────┘       └─────────────┘       └─────────────┘
       │
       ▼
┌─────────────┐       ┌─────────────┐
│Notification │       │MonitorGroup │
│    Log      │       │             │
└─────────────┘       └─────────────┘
                              │
                              ▼
                      ┌─────────────┐
                      │    Tag      │
                      │             │
                      └─────────────┘

┌─────────────┐       ┌─────────────┐
│ StatusPage  │──────<│Announcement │
│             │       │             │
└─────────────┘       └─────────────┘

┌─────────────┐
│Maintenance  │
│  Window     │
└─────────────┘
```

## Tables

### users

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| email | string | NOT NULL, UNIQUE | User email |
| encrypted_password | string | NOT NULL | Devise encrypted password |
| admin | boolean | NOT NULL, default: false | Admin flag |
| reset_password_token | string | UNIQUE | Password reset token |
| reset_password_sent_at | datetime | | Reset email sent time |
| remember_created_at | datetime | | Remember me timestamp |
| created_at | datetime | NOT NULL | Creation time |
| updated_at | datetime | NOT NULL | Update time |

### api_keys

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| user_id | bigint | FK, NOT NULL | References users |
| name | string | NOT NULL | Key name |
| key_digest | string | NOT NULL, UNIQUE | SHA256 hash of key |
| key_prefix | string(8) | NOT NULL | First 8 chars for identification |
| permissions | jsonb | default: ["read", "write"] | Permission array |
| last_used_at | datetime | | Last usage time |
| expires_at | datetime | | Expiration time |
| created_at | datetime | NOT NULL | Creation time |
| updated_at | datetime | NOT NULL | Update time |

### monitors

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| name | string | NOT NULL | Monitor name |
| monitor_type | string(50) | NOT NULL | Type: http, keyword, ping, port, heartbeat, ssl, domain, dns, api |
| status | string(20) | default: "pending" | Status: up, down, pending, paused |
| url | string(2048) | | Target URL (HTTP/keyword/API) |
| hostname | string | | Target hostname (ping/port/SSL/domain/DNS) |
| port | integer | | Target port |
| http_method | string(10) | default: "GET" | HTTP method |
| http_headers | jsonb | | Custom HTTP headers |
| http_body | text | | Request body |
| follow_redirects | boolean | default: true | Follow HTTP redirects |
| verify_ssl | boolean | default: true | Verify SSL certificates |
| keyword | string | | Keyword to search for |
| keyword_type | string(10) | | exists, not_exists |
| api_assertions | jsonb | | JSON assertion rules |
| heartbeat_token | string(64) | UNIQUE | Heartbeat URL token |
| heartbeat_interval | integer | | Expected heartbeat interval (seconds) |
| alert_days_before | integer | default: 30 | Days before SSL/domain expiry to alert |
| dns_record_type | string(10) | | DNS record type: A, AAAA, CNAME, MX, TXT |
| dns_expected_value | string | | Expected DNS value |
| interval | integer | default: 300 | Check interval (seconds) |
| timeout | integer | default: 30 | Check timeout (seconds) |
| retries | integer | default: 2 | Retry count |
| alert_threshold | integer | default: 1 | Failures before alert |
| alert_delay | integer | default: 0 | Alert delay (seconds) |
| last_check_at | datetime | | Last check time |
| last_status_change_at | datetime | | Last status change time |
| consecutive_failures | integer | default: 0 | Consecutive failure count |
| response_time | integer | | Last response time (ms) |
| monitor_group_id | bigint | FK | References monitor_groups |
| uptime_24h | decimal(5,2) | | 24-hour uptime percentage |
| uptime_7d | decimal(5,2) | | 7-day uptime percentage |
| uptime_30d | decimal(5,2) | | 30-day uptime percentage |
| description | text | | Monitor description |
| paused | boolean | default: false | Pause flag |
| created_at | datetime | NOT NULL | Creation time |
| updated_at | datetime | NOT NULL | Update time |

**Indexes**: status, heartbeat_token (unique), monitor_group_id, paused

### check_results

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| monitor_id | bigint | FK, NOT NULL | References monitors |
| status | string(20) | NOT NULL | Check status: up, down |
| response_time | integer | | Response time (ms) |
| error_message | text | | Error details |
| metadata | jsonb | | Additional metadata |
| checked_at | datetime | NOT NULL | Check timestamp |
| created_at | datetime | NOT NULL | Creation time |

**Indexes**: (monitor_id, checked_at DESC), (monitor_id, id DESC)

### incidents

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| monitor_id | bigint | FK, NOT NULL | References monitors |
| status | string(20) | default: "ongoing" | Status: ongoing, resolved |
| started_at | datetime | NOT NULL | Incident start time |
| resolved_at | datetime | | Resolution time |
| duration | integer | | Duration (seconds) |
| cause | string(50) | | Root cause category |
| cause_detail | text | | Detailed cause description |
| tags | jsonb | default: [] | Incident tags |
| excluded_from_report | boolean | default: false | Exclude from reports |
| created_at | datetime | NOT NULL | Creation time |
| updated_at | datetime | NOT NULL | Update time |

**Indexes**: monitor_id, status, (started_at DESC)

### incident_comments

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| incident_id | bigint | FK, NOT NULL | References incidents |
| content | text | | Comment content |
| created_at | datetime | NOT NULL | Creation time |
| updated_at | datetime | NOT NULL | Update time |

### notification_channels

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| name | string | NOT NULL | Channel name |
| channel_type | string(50) | NOT NULL | Type: email, slack, mattermost, feishu |
| config | jsonb | NOT NULL | Channel configuration |
| enabled | boolean | default: true | Enable flag |
| last_used_at | datetime | | Last usage time |
| last_error | text | | Last error message |
| created_at | datetime | NOT NULL | Creation time |
| updated_at | datetime | NOT NULL | Update time |

### monitor_notification_channels

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| monitor_id | bigint | FK, NOT NULL | References monitors |
| notification_channel_id | bigint | FK, NOT NULL | References notification_channels |
| notify_on_up | boolean | default: true | Notify on recovery |
| notify_on_down | boolean | default: true | Notify on down |
| notify_on_ssl_expiry | boolean | default: true | Notify on SSL expiry |
| notify_on_domain_expiry | boolean | default: true | Notify on domain expiry |
| created_at | datetime | NOT NULL | Creation time |
| updated_at | datetime | NOT NULL | Update time |

**Unique Index**: (monitor_id, notification_channel_id)

### notification_logs

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| incident_id | bigint | FK | References incidents |
| notification_channel_id | bigint | FK, NOT NULL | References notification_channels |
| monitor_id | bigint | FK, NOT NULL | References monitors |
| status | string(20) | NOT NULL | Status: sent, failed |
| message | text | | Notification message |
| error_message | text | | Error details |
| sent_at | datetime | NOT NULL | Send timestamp |
| created_at | datetime | NOT NULL | Creation time |

**Indexes**: monitor_id, (sent_at DESC)

### monitor_groups

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| name | string | | Group name |
| description | text | | Group description |
| sort_order | integer | | Display order |
| created_at | datetime | NOT NULL | Creation time |
| updated_at | datetime | NOT NULL | Update time |

### tags

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| name | string | NOT NULL, UNIQUE | Tag name |
| color | string(7) | default: "#6B7280" | HEX color code |
| created_at | datetime | NOT NULL | Creation time |
| updated_at | datetime | NOT NULL | Update time |

### monitor_tags

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| monitor_id | bigint | FK, NOT NULL | References monitors |
| tag_id | bigint | FK, NOT NULL | References tags |

**Composite PK**: (monitor_id, tag_id)

### status_pages

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| name | string | NOT NULL | Page name |
| slug | string | NOT NULL, UNIQUE | URL slug |
| logo_url | string(2048) | | Logo image URL |
| favicon_url | string(2048) | | Favicon URL |
| theme_color | string(7) | default: "#1F2937" | Theme color |
| header_bg_color | string(7) | default: "#1F2937" | Header background |
| layout | string(20) | default: "wide" | Layout: wide, compact |
| show_uptime_percentage | boolean | default: true | Show uptime % |
| show_response_time_graph | boolean | default: true | Show response graph |
| show_monitor_url | boolean | default: false | Show monitor URLs |
| show_paused_monitors | boolean | default: false | Show paused monitors |
| sort_by | string(20) | default: "status" | Sort: name, status |
| password_digest | string | | Optional password hash |
| google_analytics_id | string(50) | | GA tracking ID |
| noindex | boolean | default: false | Exclude from search |
| published | boolean | default: false | Publish flag |
| created_at | datetime | NOT NULL | Creation time |
| updated_at | datetime | NOT NULL | Update time |

### status_page_monitors

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| status_page_id | bigint | FK, NOT NULL | References status_pages |
| monitor_id | bigint | FK, NOT NULL | References monitors |
| sort_order | integer | default: 0 | Display order |
| created_at | datetime | NOT NULL | Creation time |
| updated_at | datetime | NOT NULL | Update time |

**Unique Index**: (status_page_id, monitor_id)

### announcements

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| status_page_id | bigint | FK, NOT NULL | References status_pages |
| title | string | NOT NULL | Announcement title |
| content | text | NOT NULL | Announcement content |
| status | string(20) | default: "investigating" | Status: investigating, identified, monitoring, resolved |
| started_at | datetime | NOT NULL | Start time |
| resolved_at | datetime | | Resolution time |
| created_at | datetime | NOT NULL | Creation time |
| updated_at | datetime | NOT NULL | Update time |

### announcement_updates

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| announcement_id | bigint | FK, NOT NULL | References announcements |
| content | text | NOT NULL | Update content |
| status | string(20) | | Optional status update |
| created_at | datetime | NOT NULL | Creation time |
| updated_at | datetime | NOT NULL | Update time |

### maintenance_windows

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| name | string | NOT NULL | Window name |
| description | text | | Window description |
| starts_at | datetime | NOT NULL | Start time |
| ends_at | datetime | NOT NULL | End time |
| recurrence | string(20) | | Recurrence: none, daily, weekly, monthly |
| recurrence_end_at | datetime | | Recurrence end time |
| monitor_ids | jsonb | default: [] | Affected monitor IDs |
| created_at | datetime | NOT NULL | Creation time |
| updated_at | datetime | NOT NULL | Update time |

**Indexes**: starts_at, ends_at

### response_time_stats

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| monitor_id | bigint | FK, NOT NULL | References monitors |
| period_type | string(10) | NOT NULL | Period: hourly, daily |
| period_start | datetime | NOT NULL | Period start time |
| avg_response_time | integer | | Average response time (ms) |
| min_response_time | integer | | Minimum response time (ms) |
| max_response_time | integer | | Maximum response time (ms) |
| p95_response_time | integer | | 95th percentile (ms) |
| check_count | integer | | Number of checks |
| created_at | datetime | NOT NULL | Creation time |
| updated_at | datetime | NOT NULL | Update time |

**Unique Index**: (monitor_id, period_type, period_start)
