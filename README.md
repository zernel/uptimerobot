# UptimeRobot Clone

A self-hosted website and service availability monitoring platform built with Rails 8.1.

## Features

- **10 Monitor Types**: HTTP/HTTPS, Keyword, Ping (ICMP), Port (TCP), Heartbeat/Cron, SSL Certificate, Domain Expiration, DNS, Response Time, API (JSON Assertions)
- **Alert Notifications**: Email, Webhook (Slack, Mattermost, Feishu)
- **Status Pages**: Public status pages with branding customization
- **Incident Management**: Incident tracking, root cause analysis, comments
- **Dashboard**: Monitor list/grid view, response time charts, incident history
- **Background Jobs**: PostgreSQL-based job queue (GoodJob) with cron scheduling

## Tech Stack

| Component | Choice | Version |
|-----------|--------|---------|
| Language | Ruby | 3.3+ |
| Framework | Rails | 8.1 |
| Database | PostgreSQL | 16+ |
| Task Queue | GoodJob | 3.x |
| Cron | Whenever | 1.x |
| HTTP Client | Faraday | 2.x |
| Frontend | Hotwire (Turbo + Stimulus) | - |
| CSS | Tailwind CSS | 4.x |
| Authentication | Devise | 4.9 |

## Quick Start

### Prerequisites

- Ruby 3.3+
- PostgreSQL 16+
- Node.js (for Tailwind CSS)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd uptimerobot

# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate db:seed

# Start development server
bin/dev
```

### Default Login

- **Email**: `admin@example.com`
- **Password**: `password123`

## Application URLs

| Page | URL |
|------|-----|
| Dashboard | http://localhost:3000 |
| Login | http://localhost:3000/users/sign_in |
| Public Status Page | http://localhost:3000/status/status |
| GoodJob Dashboard | http://localhost:3000/good_job |

## Project Structure

```
uptimerobot/
├── app/
│   ├── controllers/          # 15 controllers
│   ├── models/               # 19 ActiveRecord models
│   ├── services/
│   │   ├── monitors/         # 10 checker services
│   │   └── notifiers/        # 3 notification services
│   ├── jobs/                 # 6 background jobs
│   ├── mailers/              # Email notifications
│   └── views/                # ERB templates with Tailwind
├── config/
│   ├── routes.rb             # RESTful routes
│   ├── schedule.rb           # Cron schedule
│   └── initializers/         # GoodJob, Devise config
├── db/
│   ├── migrate/              # 20 migrations
│   ├── schema.rb             # Database schema
│   └── seeds.rb              # Sample data
└── docs/                     # Documentation
```

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/ARCHITECTURE.md) | System architecture and data flow |
| [API Reference](docs/API.md) | REST API endpoint documentation |
| [Database Schema](docs/DATABASE.md) | Complete database schema reference |
| [Monitoring Types](docs/MONITORING.md) | All 10 monitor checker types |
| [Deployment](docs/DEPLOYMENT.md) | Production deployment guide |
| [Contributing](CONTRIBUTING.md) | Contribution guidelines |
| [Changelog](CHANGELOG.md) | Version history |

## Development

### Running Tests

```bash
bin/rails test
```

### Background Jobs

GoodJob runs in async mode during development. Access the dashboard at `/good_job`.

### Cron Schedule

| Job | Schedule | Description |
|-----|----------|-------------|
| MonitorSchedulerJob | Every minute | Schedule monitor checks |
| DataCleanupJob | Daily 3 AM | Clean old data |
| ResponseTimeAggregationJob | Hourly | Aggregate response stats |

## Production Deployment

See [Deployment Guide](docs/DEPLOYMENT.md) for Docker and traditional deployment instructions.

## Database Schema

The application uses 18 custom tables plus GoodJob tables. See [Database Schema](docs/DATABASE.md) for complete reference.

## License

[Add your license here]
