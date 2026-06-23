# Deployment Guide

## Local Development

### Prerequisites

- Ruby 3.3+
- PostgreSQL 16+
- Node.js (for Tailwind CSS)

### Setup

```bash
# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate db:seed

# Start development server (Rails + Tailwind)
bin/dev
```

### Default Credentials

- **Email**: `admin@example.com`
- **Password**: `password123`

## Docker Deployment

### Docker Compose

Create `docker-compose.yml`:

```yaml
version: "3.8"

services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: uptimerobot
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: uptimerobot_production
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  app:
    build: .
    ports:
      - "3000:3000"
    depends_on:
      - db
    environment:
      DATABASE_URL: postgresql://uptimerobot:${DB_PASSWORD}@db:5432/uptimerobot_production
      RAILS_MASTER_KEY: ${RAILS_MASTER_KEY}
      RAILS_ENV: production
    volumes:
      - storage:/rails/storage

volumes:
  postgres_data:
  storage:
```

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | PostgreSQL connection URL | Yes |
| `RAILS_MASTER_KEY` | Rails credentials key | Yes |
| `RAILS_ENV` | Environment (production) | Yes |
| `DB_PASSWORD` | Database password | Yes |

### Build and Run

```bash
# Build image
docker compose build

# Setup database
docker compose run app bin/rails db:create db:migrate db:seed

# Start services
docker compose up -d

# View logs
docker compose logs -f app
```

## Traditional Deployment

### Server Requirements

- Ubuntu 22.04+ or similar
- Ruby 3.3+ (via rbenv or RVM)
- PostgreSQL 16+
- Nginx
- systemd

### Setup

```bash
# Install Ruby
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
rbenv install 3.3.8
rbenv global 3.3.8

# Install PostgreSQL
sudo apt install postgresql postgresql-contrib
sudo systemctl enable postgresql

# Install Node.js (for Tailwind)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install nodejs

# Clone application
git clone <repository-url> /opt/uptimerobot
cd /opt/uptimerobot

# Install dependencies
gem install bundler
bundle install

# Configure database
sudo -u postgres createuser uptimerobot
sudo -u postgres createdb uptimerobot_production -O uptimerobot

# Set environment variables
export DATABASE_URL="postgresql://uptimerobot:password@localhost/uptimerobot_production"
export RAILS_MASTER_KEY=$(cat config/master.key)
export RAILS_ENV=production

# Setup application
bin/rails db:migrate
bin/rails db:seed
bin/rails assets:precompile

# Create systemd service
sudo nano /etc/systemd/system/uptimerobot.service
```

### Systemd Service

```ini
[Unit]
Description=UptimeRobot Rails Application
After=network.target postgresql.service

[Service]
Type=simple
User=deploy
WorkingDirectory=/opt/uptimerobot
Environment=RAILS_ENV=production
Environment=DATABASE_URL=postgresql://uptimerobot:password@localhost/uptimerobot_production
Environment=RAILS_MASTER_KEY=<your-master-key>
ExecStart=/home/deploy/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable uptimerobot
sudo systemctl start uptimerobot
```

### Nginx Configuration

```nginx
server {
    listen 80;
    server_name uptime.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /assets {
        alias /opt/uptimerobot/public/assets;
        gzip_static on;
        expires max;
        add_header Cache-Control public;
    }

    location /cable {
        proxy_pass http://127.0.0.1:3000/cable;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## Background Jobs

GoodJob runs in-process during development and as a separate process in production.

### Production Job Worker

Add to systemd:

```ini
[Unit]
Description=UptimeRobot Job Worker
After=network.target postgresql.service

[Service]
Type=simple
User=deploy
WorkingDirectory=/opt/uptimerobot
Environment=RAILS_ENV=production
Environment=DATABASE_URL=postgresql://uptimerobot:password@localhost/uptimerobot_production
Environment=RAILS_MASTER_KEY=<your-master-key>
ExecStart=/home/deploy/.rbenv/shims/bundle exec good_job start
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

## Monitoring

### Health Check

```
GET /up
```

Returns 200 OK if application is running.

### GoodJob Dashboard

Access at `/good_job` (admin only) to monitor:
- Job queue status
- Failed jobs
- Cron schedules
- Execution history

## Backup

### Database Backup

```bash
pg_dump -U uptimerobot uptimerobot_production > backup_$(date +%Y%m%d).sql
```

### Restore

```bash
psql -U uptimerobot uptimerobot_production < backup_20260623.sql
```

## SSL/TLS

Use Let's Encrypt with Certbot:

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d uptime.example.com
```
