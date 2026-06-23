# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-06-23

### Added

- Initial release
- Rails 8.1.3 application with PostgreSQL
- 10 monitor types: HTTP, Keyword, Ping, Port, Heartbeat, SSL, Domain, DNS, Response Time, API
- Dashboard with monitor statistics
- Monitor CRUD with pause/resume/reset
- Incident management with comments
- Notification channels: Email, Slack, Mattermost, Feishu
- Status pages with public access
- Announcements and maintenance windows
- Monitor groups and tags
- Background jobs with GoodJob
- Cron scheduling with Whenever
- Tailwind CSS UI
- Devise authentication
- GoodJob dashboard (admin only)
- Heartbeat endpoint for cron monitoring
- Public status pages with optional password protection
- Docker deployment support
- Comprehensive documentation

### Technical

- 18 database tables with proper constraints and indexes
- 19 ActiveRecord models
- 15 controllers
- 10 checker services
- 3 notifier services
- 6 background jobs
- 43 view templates
- Stimulus controllers for interactivity
