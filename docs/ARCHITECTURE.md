# Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                          Nginx (Reverse Proxy)                    │
│                    SSL Termination / Static Files / Load Balance  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Rails Application (Puma)                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │ Web UI   │  │ API      │  │ Status   │  │ Admin    │        │
│  │ (Hotwire)│  │ (Internal)│  │ Page     │  │ Panel    │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
└─────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│  PostgreSQL   │     │   Good Job    │     │   Whenever    │
│  (Database)   │     │  (Job Queue)  │     │  (Scheduler)  │
└───────────────┘     └───────────────┘     └───────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Monitor Checkers                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │ HTTP     │  │ Ping     │  │ Port     │  │ SSL/DNS  │        │
│  │ Checker  │  │ Checker  │  │ Checker  │  │ Checker  │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Notification Dispatchers                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                       │
│  │ Email    │  │ Slack    │  │ Feishu   │                       │
│  │ Notifier │  │ Webhook  │  │ Webhook  │                       │
│  └──────────┘  └──────────┘  └──────────┘                       │
└─────────────────────────────────────────────────────────────────┘
```

## Core Components

### MonitorScheduler

**Responsibility**: Trigger monitor checks on schedule

```
Whenever (cron) → Good Job (queue) → Checker (execute)
```

- Scans all active monitors every minute
- Checks if monitor's interval has elapsed
- Uses GoodJob concurrency control to prevent duplicate checks

### MonitorChecker

**Responsibility**: Execute specific monitoring check logic

```
Input: SiteMonitor configuration
Output: CheckResult (success/failure, response_time, metadata)
```

- Each monitor type has a dedicated Checker class
- Unified interface: `#check` → `CheckResult`
- Includes timeout control and error handling

### StatusManager

**Responsibility**: Manage monitor state transitions

```
Input: CheckResult
Output: State update + trigger notifications
```

- State machine: `up` ↔ `down` + `pending` (initial)
- Consecutive failure counting
- Alert threshold evaluation

### NotificationDispatcher

**Responsibility**: Send alert notifications to channels

```
Input: Incident
Output: Notification send results
```

- Multi-channel parallel sending
- Failure retry mechanism
- Notification log recording

## Data Flow

```
[Scheduled Trigger]
    │
    ▼
[Scan Active Monitors] → [Filter by Interval] → [Enqueue Check Job]
    │
    ▼
[Execute Check] → [Record Result] → [Update Response Time Stats]
    │
    ▼
[State Evaluation]
    │
    ├─ State Unchanged → End
    │
    └─ State Changed
         │
         ├─ up → down → Create Incident + Send "Down" Notification
         │
         └─ down → up → Update Incident + Send "Recovery" Notification
```

## Model Relationships

```
User
  └── ApiKey

SiteMonitor
  ├── CheckResult
  ├── Incident
  │     └── IncidentComment
  ├── MonitorNotificationChannel
  │     └── NotificationChannel
  │           └── NotificationLog
  ├── MonitorTag
  │     └── Tag
  ├── StatusPageMonitor
  │     └── StatusPage
  │           └── Announcement
  │                 └── AnnouncementUpdate
  ├── MonitorGroup
  └── ResponseTimeStat

MaintenanceWindow (independent)
```

## Key Design Decisions

### 1. SiteMonitor Naming

The model is named `SiteMonitor` instead of `Monitor` to avoid conflict with Ruby's stdlib `Monitor` class (thread synchronization). The database table remains `monitors`.

### 2. PostgreSQL-Based Job Queue

GoodJob uses PostgreSQL instead of Redis, reducing infrastructure dependencies. All job state is stored in the database.

### 3. Single Admin User

The system supports a single admin user (no multi-user/team). This simplifies the auth model for self-hosted deployments.

### 4. JSONB for Flexible Configuration

Monitor configuration (HTTP headers, API assertions, etc.) uses JSONB columns for flexibility without schema changes.

### 5. Time-Series Data

Check results and response time stats are stored with time-based indexes for efficient historical queries.

## Security Considerations

- **Authentication**: Devise with bcrypt password hashing
- **API Keys**: SHA256 digests stored (not raw keys)
- **Heartbeat Tokens**: Unique per monitor, URL-safe
- **SSL Verification**: Configurable per monitor
- **GoodJob Dashboard**: Admin-only access
- **Public Status Pages**: Optional password protection
