# Monitoring Types

## Overview

The application supports 10 monitoring types, each implemented as a dedicated checker service in `app/services/monitors/`.

## Monitor Types

### 1. HTTP/HTTPS Monitor

**Purpose**: Monitor web endpoints for availability

**Configuration**:
- `url`: Target URL (required)
- `http_method`: GET, POST, PUT, DELETE (default: GET)
- `http_headers`: Custom headers (JSON)
- `http_body`: Request body
- `follow_redirects`: Follow HTTP redirects (default: true)
- `verify_ssl`: Verify SSL certificates (default: true)

**Check Logic**:
1. Send HTTP request to target URL
2. Check response status code (200 = success)
3. Record response time

**Checker**: `Monitors::HttpChecker`

**Example**:
```ruby
SiteMonitor.create!(
  name: "Production API",
  monitor_type: "http",
  url: "https://api.example.com/health",
  http_method: "GET",
  interval: 300
)
```

---

### 2. Keyword Monitor

**Purpose**: Check if a webpage contains (or doesn't contain) specific text

**Configuration**:
- `url`: Target URL (required)
- `keyword`: Text to search for (required)
- `keyword_type`: "exists" or "not_exists"

**Check Logic**:
1. Fetch webpage content
2. Search for keyword
3. If keyword_type is "exists": success if found
4. If keyword_type is "not_exists": success if NOT found

**Checker**: `Monitors::KeywordChecker`

**Example**:
```ruby
SiteMonitor.create!(
  name: "Homepage Content",
  monitor_type: "keyword",
  url: "https://example.com",
  keyword: "Welcome",
  keyword_type: "exists",
  interval: 600
)
```

---

### 3. Ping Monitor (ICMP)

**Purpose**: Check server reachability via ICMP ping

**Configuration**:
- `hostname`: Target host (required)
- `timeout`: Ping timeout (default: 30s)

**Check Logic**:
1. Send ICMP ping to hostname
2. Check if host responds
3. Record round-trip time

**Checker**: `Monitors::PingChecker`

**Note**: Requires ICMP permissions (may need root/admin on some systems)

**Example**:
```ruby
SiteMonitor.create!(
  name: "Main Server",
  monitor_type: "ping",
  hostname: "192.168.1.1",
  interval: 300
)
```

---

### 4. Port Monitor (TCP)

**Purpose**: Check if a TCP port is open and accepting connections

**Configuration**:
- `hostname`: Target host (required)
- `port`: Target port (required)

**Check Logic**:
1. Attempt TCP connection to host:port
2. If connection succeeds: port is open
3. Record connection time

**Checker**: `Monitors::PortChecker`

**Example**:
```ruby
SiteMonitor.create!(
  name: "Database Server",
  monitor_type: "port",
  hostname: "db.example.com",
  port: 5432,
  interval: 300
)
```

---

### 5. Heartbeat/Cron Monitor

**Purpose**: Monitor scheduled tasks by expecting periodic check-ins

**Configuration**:
- `heartbeat_token`: Unique token for heartbeat URL (auto-generated)
- `heartbeat_interval`: Expected interval between heartbeats (seconds)

**Check Logic**:
1. Check time since last heartbeat
2. If within expected interval + 10% grace: success
3. If overdue: failure

**Checker**: `Monitors::HeartbeatChecker`

**Usage**:
```
# Your cron job sends heartbeat:
curl https://your-app.com/heartbeat/:token

# Monitor checks if heartbeat arrived on time
```

**Example**:
```ruby
monitor = SiteMonitor.create!(
  name: "Daily Backup",
  monitor_type: "heartbeat",
  heartbeat_interval: 86400,  # 24 hours
  interval: 3600              # Check every hour
)
# Use monitor.heartbeat_token in your cron job
```

---

### 6. SSL Certificate Monitor

**Purpose**: Monitor SSL certificate expiration

**Configuration**:
- `hostname`: Target hostname (required)
- `alert_days_before`: Days before expiry to alert (default: 30)

**Check Logic**:
1. Connect to hostname on port 443
2. Retrieve SSL certificate
3. Check expiration date
4. Calculate days until expiry

**Checker**: `Monitors::SslChecker`

**Example**:
```ruby
SiteMonitor.create!(
  name: "Main Domain SSL",
  monitor_type: "ssl",
  hostname: "example.com",
  alert_days_before: 30,
  interval: 86400  # Check daily
)
```

---

### 7. Domain Expiration Monitor

**Purpose**: Monitor domain registration expiration

**Configuration**:
- `hostname`: Domain name (required)
- `alert_days_before`: Days before expiry to alert (default: 30)

**Check Logic**:
1. Query WHOIS for domain
2. Extract expiration date
3. Calculate days until expiry

**Checker**: `Monitors::DomainChecker`

**Note**: Requires WHOIS gem and access to WHOIS servers

**Example**:
```ruby
SiteMonitor.create!(
  name: "Main Domain",
  monitor_type: "domain",
  hostname: "example.com",
  alert_days_before: 60,
  interval: 86400
)
```

---

### 8. DNS Monitor

**Purpose**: Monitor DNS record resolution

**Configuration**:
- `hostname`: Domain to query (required)
- `dns_record_type`: Record type: A, AAAA, CNAME, MX, TXT
- `dns_expected_value`: Expected value (optional)

**Check Logic**:
1. Query DNS for hostname and record type
2. If expected_value set: check if it matches
3. If expected_value empty: check if any records exist

**Checker**: `Monitors::DnsChecker`

**Example**:
```ruby
SiteMonitor.create!(
  name: "DNS A Record",
  monitor_type: "dns",
  hostname: "example.com",
  dns_record_type: "A",
  dns_expected_value: "93.184.216.34",
  interval: 3600
)
```

---

### 9. Response Time Monitor

**Purpose**: Monitor response time and alert on degradation

**Configuration**:
- Same as HTTP monitor
- Response time tracked automatically

**Check Logic**:
1. Execute HTTP check
2. Record response time
3. Store in response_time_stats for trending

**Note**: Response time monitoring is built into the HTTP checker. No separate checker needed.

---

### 10. API Monitor (JSON Assertions)

**Purpose**: Monitor API endpoints with JSON response validation

**Configuration**:
- `url`: API endpoint (required)
- `http_method`: HTTP method
- `http_headers`: Custom headers
- `http_body`: Request body
- `api_assertions`: Array of assertion rules

**Assertion Format**:
```json
[
  { "path": "$.status", "operator": "eq", "value": "ok" },
  { "path": "$.data.count", "operator": "gt", "value": "0" },
  { "path": "$.error", "operator": "not_exists", "value": "" }
]
```

**Operators**:
- `eq`: Equals
- `ne`: Not equals
- `gt`: Greater than
- `lt`: Less than
- `gte`: Greater than or equal
- `lte`: Less than or equal
- `contains`: String contains
- `not_contains`: String does not contain
- `exists`: Value exists
- `not_exists`: Value does not exist

**Checker**: `Monitors::ApiChecker`

**Example**:
```ruby
SiteMonitor.create!(
  name: "Health API",
  monitor_type: "api",
  url: "https://api.example.com/health",
  http_method: "GET",
  api_assertions: [
    { "path" => "status", "operator" => "eq", "value" => "healthy" },
    { "path" => "uptime", "operator" => "gt", "value" => "99" }
  ],
  interval: 300
)
```

---

## Base Checker

All checkers inherit from `Monitors::BaseChecker`:

```ruby
module Monitors
  class BaseChecker
    attr_reader :monitor, :start_time

    def initialize(monitor)
      @monitor = monitor
    end

    def check
      raise NotImplementedError
    end

    private

    def response_time
      return nil unless start_time
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).to_i
    end

    def start_timer
      @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
```

## Adding New Monitor Types

1. Create checker in `app/services/monitors/`:
```ruby
module Monitors
  class MyChecker < BaseChecker
    def check
      start_timer
      # Implement check logic
      CheckResult.new(monitor: monitor, status: :up, response_time: response_time)
    end
  end
end
```

2. Add type to SiteMonitor enum in `app/models/site_monitor.rb`

3. Add case to `MonitorCheckJob#checker_for`

4. Add migration for any new columns
