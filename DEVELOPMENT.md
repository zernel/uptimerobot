# UptimeRobot 复刻项目 - 开发部署文档

> 技术规格与实现指南
> 创建日期：2026-06-23

---

## 目录

1. [项目概述](#1-项目概述)
2. [技术栈](#2-技术栈)
3. [系统架构](#3-系统架构)
4. [数据库设计](#4-数据库设计)
5. [监控引擎实现](#5-监控引擎实现)
6. [告警与通知系统](#6-告警与通知系统)
7. [状态页面](#7-状态页面)
8. [事件管理](#8-事件管理)
9. [用户界面设计](#9-用户界面设计)
10. [Docker 部署](#10-docker-部署)
11. [开发计划](#11-开发计划)
12. [附录](#附录)

---

## 1. 项目概述

### 1.1 产品定位

构建一个自托管的网站和服务可用性监控平台，核心能力复刻 UptimeRobot，简化用户管理和部分集成。

### 1.2 功能范围

#### 实现功能

| 类别 | 功能 |
|------|------|
| **监控类型** | HTTP/HTTPS、关键词、Ping (ICMP)、端口 (TCP/UDP)、心跳/Cron、SSL 证书、域名过期、DNS、响应时间、API 监控 (JSON 断言) |
| **告警通知** | Email、Webhook (Slack/Mattermost/飞书) |
| **状态页面** | 公开状态页面、品牌定制、事件公告 |
| **事件管理** | 事件记录、状态跟踪、根因分类 |
| **用户系统** | 单管理员账号、API Key 管理 |
| **仪表盘** | 监控器列表/网格视图、响应时间图表、事件历史 |

#### 不实现功能

- 多用户/团队协作
- 多位置分布式监控
- 网站变更检测（视觉对比）
- SMS/语音通知
- 自定义域名（CNAME）
- 用户订阅功能
- 移动应用
- 对外 REST API

### 1.3 核心价值主张

- **自托管**：数据完全掌控，无第三方依赖
- **轻量级**：单服务器部署，资源占用低
- **易维护**：Rails 生态成熟，代码可读性强
- **可扩展**：架构预留扩展点，后续可按需添加功能

---

## 2. 技术栈

### 2.1 后端框架

| 组件 | 选型 | 版本 | 说明 |
|------|------|------|------|
| 语言 | Ruby | 3.3+ | 稳定、成熟的生态 |
| 框架 | Rails | 8.0 | 最新稳定版，内置 Kamal 部署 |
| 数据库 | PostgreSQL | 16 | 主数据库 |
| 任务队列 | Good Job | 3.x | 基于 PostgreSQL，无需 Redis |
| 定时任务 | Whenever | 1.x | Cron 表达式管理 |
| HTTP 客户端 | Faraday | 2.x | 灵活的 HTTP 库 |
| 监控检查 | Net::Ping, Socket, OpenSSL | 标准库 | 底层网络操作 |

### 2.2 前端框架

| 组件 | 选型 | 说明 |
|------|------|------|
| 框架 | Hotwire (Turbo + Stimulus) | Rails 原生方案 |
| 模板 | ERB | 服务端渲染 |
| 样式 | Tailwind CSS | 实用优先的 CSS |
| 图表 | Chart.js | 响应时间趋势图 |
| 图标 | Heroicons | SVG 图标库 |
| 实时更新 | Turbo Streams | WebSocket 推送 |

### 2.3 基础设施

| 组件 | 选型 | 说明 |
|------|------|------|
| 容器化 | Docker + Docker Compose | 单机部署 |
| Web 服务器 | Puma | Rails 默认 |
| 反向代理 | Nginx | SSL 终止、静态文件 |
| 进程管理 | systemd / Docker | 守护进程 |

---

## 3. 系统架构

### 3.1 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                          Nginx (反向代理)                         │
│                    SSL 终止 / 静态文件 / 负载                     │
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
│   PostgreSQL  │     │   Good Job    │     │   Whenever    │
│   (主数据库)   │     │  (任务队列)    │     │  (定时调度)    │
└───────────────┘     └───────────────┘     └───────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     监控检查器 (Checker)                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │ HTTP     │  │ Ping     │  │ Port     │  │ SSL/DNS  │        │
│  │ Checker  │  │ Checker  │  │ Checker  │  │ Checker  │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     通知分发器 (Notifier)                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                       │
│  │ Email    │  │ Slack    │  │ 飞书      │                       │
│  │ Notifier │  │ Webhook  │  │ Webhook  │                       │
│  └──────────┘  └──────────┘  └──────────┘                       │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 核心组件职责

#### 监控调度器 (MonitorScheduler)

```
职责：定时触发监控检查
实现：Whenever (cron) → Good Job (队列) → Checker (执行)
```

- 每分钟扫描所有活跃监控器
- 根据监控器的 `interval` 决定是否执行
- 使用 Good Job 的并发控制避免重复检查

#### 监控检查器 (MonitorChecker)

```
职责：执行具体的监控检查逻辑
输入：Monitor 配置
输出：CheckResult (success/failure, response_time, metadata)
```

- 每种监控类型对应一个 Checker 类
- 统一接口：`#check` → `CheckResult`
- 包含超时控制和错误处理

#### 状态管理器 (StatusManager)

```
职责：管理监控器状态转换
输入：CheckResult
输出：状态更新 + 触发通知
```

- 状态机：`up` ↔ `down` + `pending` (初始)
- 连续失败计数
- 触发告警阈值判断

#### 通知分发器 (NotificationDispatcher)

```
职责：发送告警通知到各渠道
输入：Incident (事件)
输出：通知发送结果
```

- 支持多渠道并行发送
- 失败重试机制
- 通知日志记录

### 3.3 数据流

```
[定时调度] 
    │
    ▼
[扫描活跃监控器] → [按 interval 过滤] → [入队检查任务]
    │
    ▼
[执行检查] → [记录检查结果] → [更新响应时间统计]
    │
    ▼
[状态判断]
    │
    ├─ 状态未变 → 结束
    │
    └─ 状态变化
         │
         ├─ up → down → 创建 Incident + 发送"宕机"通知
         │
         └─ down → up → 更新 Incident + 发送"恢复"通知
```

---

## 4. 数据库设计

### 4.1 ER 图

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│   Monitor   │──────<│ CheckResult │       │    User     │
│             │       │             │       │  (单管理员)  │
└─────────────┘       └─────────────┘       └─────────────┘
       │                                           │
       │                                           │
       ▼                                           ▼
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│  Incident   │──────<│  Comment    │       │  ApiKey     │
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

### 4.2 表结构详细设计

#### 4.2.1 users - 用户表

```sql
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  encrypted_password VARCHAR(255) NOT NULL,
  name VARCHAR(255),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

#### 4.2.2 api_keys - API 密钥表

```sql
CREATE TABLE api_keys (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  name VARCHAR(255) NOT NULL,
  key_digest VARCHAR(255) NOT NULL UNIQUE,  -- SHA256 哈希
  key_prefix VARCHAR(8) NOT NULL,           -- 前缀用于识别
  permissions JSONB DEFAULT '["read", "write"]',
  last_used_at TIMESTAMP,
  expires_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_api_keys_key_digest ON api_keys(key_digest);
CREATE INDEX idx_api_keys_user_id ON api_keys(user_id);
```

#### 4.2.3 monitors - 监控器表

```sql
CREATE TABLE monitors (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  monitor_type VARCHAR(50) NOT NULL,  -- http, keyword, ping, port, heartbeat, ssl, domain, dns, response_time, api
  status VARCHAR(20) DEFAULT 'pending',  -- up, down, pending, paused
  
  -- 目标配置
  url VARCHAR(2048),                    -- HTTP/关键词/API 监控
  hostname VARCHAR(255),                -- Ping/端口/SSL/域名/DNS 监控
  port INTEGER,                         -- 端口监控
  
  -- HTTP 相关配置
  http_method VARCHAR(10) DEFAULT 'GET',
  http_headers JSONB,
  http_body TEXT,
  follow_redirects BOOLEAN DEFAULT TRUE,
  verify_ssl BOOLEAN DEFAULT TRUE,
  
  -- 关键词监控配置
  keyword VARCHAR(255),
  keyword_type VARCHAR(10),  -- exists, not_exists
  
  -- API 监控配置 (JSON 断言)
  api_assertions JSONB,  -- [{path: "$.status", operator: "eq", value: "ok"}]
  
  -- 心跳监控配置
  heartbeat_token VARCHAR(64) UNIQUE,
  heartbeat_interval INTEGER,  -- 期望的间隔秒数
  
  -- SSL/域名监控配置
  alert_days_before INTEGER DEFAULT 30,  -- 提前几天告警
  
  -- DNS 监控配置
  dns_record_type VARCHAR(10),  -- A, AAAA, CNAME, MX, TXT
  dns_expected_value VARCHAR(255),
  
  -- 监控设置
  interval INTEGER DEFAULT 300,         -- 检查间隔（秒）
  timeout INTEGER DEFAULT 30,           -- 超时时间（秒）
  retries INTEGER DEFAULT 2,            -- 重试次数
  
  -- 告警配置
  alert_threshold INTEGER DEFAULT 1,    -- 连续失败几次后告警
  alert_delay INTEGER DEFAULT 0,        -- 告警延迟（秒）
  
  -- 状态追踪
  last_check_at TIMESTAMP,
  last_status_change_at TIMESTAMP,
  consecutive_failures INTEGER DEFAULT 0,
  response_time INTEGER,                -- 最近一次响应时间（毫秒）
  
  -- 分组和标签
  monitor_group_id BIGINT REFERENCES monitor_groups(id),
  
  -- 统计
  uptime_24h DECIMAL(5,2),
  uptime_7d DECIMAL(5,2),
  uptime_30d DECIMAL(5,2),
  
  -- 元数据
  description TEXT,
  paused BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_monitors_status ON monitors(status);
CREATE INDEX idx_monitors_heartbeat_token ON monitors(heartbeat_token);
CREATE INDEX idx_monitors_monitor_group_id ON monitors(monitor_group_id);
CREATE INDEX idx_monitors_paused ON monitors(paused);
```

#### 4.2.4 check_results - 检查结果表

```sql
CREATE TABLE check_results (
  id BIGSERIAL PRIMARY KEY,
  monitor_id BIGINT NOT NULL REFERENCES monitors(id),
  status VARCHAR(20) NOT NULL,  -- up, down
  response_time INTEGER,        -- 毫秒
  error_message TEXT,
  metadata JSONB,               -- 额外信息（HTTP 状态码、响应头等）
  checked_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL
);

-- 按时间分区（建议每月一个分区）
CREATE INDEX idx_check_results_monitor_id_checked_at 
  ON check_results(monitor_id, checked_at DESC);

-- 用于查询最近的检查结果
CREATE INDEX idx_check_results_monitor_id_id 
  ON check_results(monitor_id, id DESC);
```

#### 4.2.5 incidents - 事件表

```sql
CREATE TABLE incidents (
  id BIGSERIAL PRIMARY KEY,
  monitor_id BIGINT NOT NULL REFERENCES monitors(id),
  status VARCHAR(20) DEFAULT 'ongoing',  -- ongoing, resolved
  
  -- 时间信息
  started_at TIMESTAMP NOT NULL,
  resolved_at TIMESTAMP,
  duration INTEGER,  -- 持续时间（秒），解决后计算
  
  -- 根因分析
  cause VARCHAR(50),  -- timeout, connection_refused, ssl_error, dns_error, keyword_not_found, etc.
  cause_detail TEXT,
  
  -- 标签
  tags JSONB DEFAULT '[]',
  
  -- 排除标记
  excluded_from_report BOOLEAN DEFAULT FALSE,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_incidents_monitor_id ON incidents(monitor_id);
CREATE INDEX idx_incidents_status ON incidents(status);
CREATE INDEX idx_incidents_started_at ON incidents(started_at DESC);
```

#### 4.2.6 incident_comments - 事件评论表

```sql
CREATE TABLE incident_comments (
  id BIGSERIAL PRIMARY KEY,
  incident_id BIGINT NOT NULL REFERENCES incidents(id),
  content TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_incident_comments_incident_id ON incident_comments(incident_id);
```

#### 4.2.7 notification_channels - 通知渠道表

```sql
CREATE TABLE notification_channels (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  channel_type VARCHAR(50) NOT NULL,  -- email, slack, mattermost, feishu
  
  -- 渠道配置
  config JSONB NOT NULL,
  -- email: {address: "admin@example.com"}
  -- slack: {webhook_url: "https://hooks.slack.com/..."}
  -- mattermost: {webhook_url: "https://...", channel: "#alerts"}
  -- feishu: {webhook_url: "https://open.feishu.cn/..."}
  
  -- 状态
  enabled BOOLEAN DEFAULT TRUE,
  last_used_at TIMESTAMP,
  last_error TEXT,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

#### 4.2.8 monitor_notification_channels - 监控器通知关联表

```sql
CREATE TABLE monitor_notification_channels (
  id BIGSERIAL PRIMARY KEY,
  monitor_id BIGINT NOT NULL REFERENCES monitors(id),
  notification_channel_id BIGINT NOT NULL REFERENCES notification_channels(id),
  
  -- 通知触发条件
  notify_on_up BOOLEAN DEFAULT TRUE,
  notify_on_down BOOLEAN DEFAULT TRUE,
  notify_on_ssl_expiry BOOLEAN DEFAULT TRUE,
  notify_on_domain_expiry BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  
  UNIQUE(monitor_id, notification_channel_id)
);
```

#### 4.2.9 notification_logs - 通知日志表

```sql
CREATE TABLE notification_logs (
  id BIGSERIAL PRIMARY KEY,
  incident_id BIGINT REFERENCES incidents(id),
  notification_channel_id BIGINT NOT NULL REFERENCES notification_channels(id),
  monitor_id BIGINT NOT NULL REFERENCES monitors(id),
  
  status VARCHAR(20) NOT NULL,  -- sent, failed
  message TEXT,
  error_message TEXT,
  
  sent_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_notification_logs_monitor_id ON notification_logs(monitor_id);
CREATE INDEX idx_notification_logs_sent_at ON notification_logs(sent_at DESC);
```

#### 4.2.10 monitor_groups - 监控器分组表

```sql
CREATE TABLE monitor_groups (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

#### 4.2.11 tags - 标签表

```sql
CREATE TABLE tags (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL UNIQUE,
  color VARCHAR(7) DEFAULT '#6B7280',  -- HEX 颜色
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

#### 4.2.12 monitor_tags - 监控器标签关联表

```sql
CREATE TABLE monitor_tags (
  monitor_id BIGINT NOT NULL REFERENCES monitors(id),
  tag_id BIGINT NOT NULL REFERENCES tags(id),
  PRIMARY KEY (monitor_id, tag_id)
);
```

#### 4.2.13 status_pages - 状态页面表

```sql
CREATE TABLE status_pages (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL UNIQUE,  -- URL 友好的标识
  
  -- 品牌定制
  logo_url VARCHAR(2048),
  favicon_url VARCHAR(2048),
  theme_color VARCHAR(7) DEFAULT '#1F2937',
  header_bg_color VARCHAR(7) DEFAULT '#1F2937',
  layout VARCHAR(20) DEFAULT 'wide',  -- wide, compact
  
  -- 内容控制
  show_uptime_percentage BOOLEAN DEFAULT TRUE,
  show_response_time_graph BOOLEAN DEFAULT TRUE,
  show_monitor_url BOOLEAN DEFAULT FALSE,
  show_paused_monitors BOOLEAN DEFAULT FALSE,
  sort_by VARCHAR(20) DEFAULT 'status',  -- name, status
  
  -- 高级设置
  password_digest VARCHAR(255),  -- 可选密码保护
  google_analytics_id VARCHAR(50),
  noindex BOOLEAN DEFAULT FALSE,
  
  -- 状态
  published BOOLEAN DEFAULT FALSE,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_status_pages_slug ON status_pages(slug);
```

#### 4.2.14 status_page_monitors - 状态页面监控器关联表

```sql
CREATE TABLE status_page_monitors (
  id BIGSERIAL PRIMARY KEY,
  status_page_id BIGINT NOT NULL REFERENCES status_pages(id),
  monitor_id BIGINT NOT NULL REFERENCES monitors(id),
  sort_order INTEGER DEFAULT 0,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  
  UNIQUE(status_page_id, monitor_id)
);
```

#### 4.2.15 announcements - 公告表

```sql
CREATE TABLE announcements (
  id BIGSERIAL PRIMARY KEY,
  status_page_id BIGINT NOT NULL REFERENCES status_pages(id),
  
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'investigating',  -- investigating, identified, monitoring, resolved
  
  -- 时间
  started_at TIMESTAMP NOT NULL,
  resolved_at TIMESTAMP,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_announcements_status_page_id ON announcements(status_page_id);
CREATE INDEX idx_announcements_status ON announcements(status);
```

#### 4.2.16 announcement_updates - 公告更新表

```sql
CREATE TABLE announcement_updates (
  id BIGSERIAL PRIMARY KEY,
  announcement_id BIGINT NOT NULL REFERENCES announcements(id),
  
  content TEXT NOT NULL,
  status VARCHAR(20),  -- 可选更新状态
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_announcement_updates_announcement_id ON announcement_updates(announcement_id);
```

#### 4.2.17 maintenance_windows - 维护窗口表

```sql
CREATE TABLE maintenance_windows (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  
  -- 时间配置
  starts_at TIMESTAMP NOT NULL,
  ends_at TIMESTAMP NOT NULL,
  
  -- 重复配置
  recurrence VARCHAR(20),  -- none, daily, weekly, monthly
  recurrence_end_at TIMESTAMP,
  
  -- 关联监控器
  monitor_ids BIGINT[] DEFAULT '{}',
  -- 空数组表示应用于所有监控器
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_maintenance_windows_starts_at ON maintenance_windows(starts_at);
CREATE INDEX idx_maintenance_windows_ends_at ON maintenance_windows(ends_at);
```

#### 4.2.18 response_time_stats - 响应时间统计表（聚合）

```sql
CREATE TABLE response_time_stats (
  id BIGSERIAL PRIMARY KEY,
  monitor_id BIGINT NOT NULL REFERENCES monitors(id),
  
  -- 时间维度
  period_type VARCHAR(10) NOT NULL,  -- hourly, daily
  period_start TIMESTAMP NOT NULL,
  
  -- 统计数据
  avg_response_time INTEGER,
  min_response_time INTEGER,
  max_response_time INTEGER,
  p95_response_time INTEGER,
  check_count INTEGER,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  
  UNIQUE(monitor_id, period_type, period_start)
);

CREATE INDEX idx_response_time_stats_monitor_id_period 
  ON response_time_stats(monitor_id, period_type, period_start DESC);
```

### 4.3 数据保留策略

```ruby
# config/initializers/data_retention.rb

module DataRetention
  # 检查结果保留期限
  CHECK_RESULTS_RETENTION = {
    hourly: 7.days,    # 小时粒度：7 天
    daily: 90.days,    # 天粒度：90 天
    monthly: 1.year    # 月粒度：1 年
  }.freeze

  # 通知日志保留期限
  NOTIFICATION_LOGS_RETENTION = 90.days

  # 响应时间统计保留期限
  RESPONSE_TIME_STATS_RETENTION = {
    hourly: 30.days,
    daily: 1.year
  }.freeze
end
```

### 4.4 清理任务

```ruby
# app/jobs/data_cleanup_job.rb

class DataCleanupJob < ApplicationJob
  queue_as :maintenance

  def perform
    cleanup_check_results
    cleanup_notification_logs
    cleanup_response_time_stats
  end

  private

  def cleanup_check_results
    # 保留最近 7 天的原始数据
    CheckResult.where('created_at < ?', 7.days.ago).delete_all
    
    # 小时聚合数据保留 30 天
    ResponseTimeStat.where(period_type: 'hourly')
                    .where('period_start < ?', 30.days.ago)
                    .delete_all
    
    # 天聚合数据保留 1 年
    ResponseTimeStat.where(period_type: 'daily')
                    .where('period_start < ?', 1.year.ago)
                    .delete_all
  end

  def cleanup_notification_logs
    NotificationLog.where('created_at < ?', 90.days.ago).delete_all
  end

  def cleanup_response_time_stats
    # 已在 cleanup_check_results 中处理
  end
end
```

---

## 5. 监控引擎实现

### 5.1 监控类型实现

#### 5.1.1 HTTP/HTTPS 监控

```ruby
# app/services/monitors/http_checker.rb

module Monitors
  class HttpChecker < BaseChecker
    def check
      response = connection.send(http_method) do |req|
        req.url monitor.url
        req.headers.merge!(custom_headers)
        req.body = monitor.http_body if monitor.http_body.present?
        req.options.timeout = monitor.timeout
        req.options.open_timeout = 10
      end

      CheckResult.new(
        monitor: monitor,
        status: determine_status(response),
        response_time: response_time,
        metadata: {
          http_status: response.status,
          response_size: response.body&.length,
          redirect_count: response.env.url.to_s != monitor.url ? 1 : 0
        }
      )
    rescue Faraday::Error => e
      CheckResult.new(
        monitor: monitor,
        status: :down,
        error_message: e.message,
        metadata: { error_class: e.class.name }
      )
    end

    private

    def connection
      @connection ||= Faraday.new do |f|
        f.request :url_encoded
        f.adapter Faraday.default_adapter
        f.ssl.verify = monitor.verify_ssl?
      end
    end

    def http_method
      (monitor.http_method || 'get').downcase.to_sym
    end

    def custom_headers
      (monitor.http_headers || {}).transform_keys(&:to_s)
    end

    def determine_status(response)
      success_codes = monitor.http_success_codes || [200]
      success_codes.include?(response.status) ? :up : :down
    end
  end
end
```

#### 5.1.2 关键词监控

```ruby
# app/services/monitors/keyword_checker.rb

module Monitors
  class KeywordChecker < BaseChecker
    def check
      response = connection.get(monitor.url)
      body = response.body.to_s
      keyword_found = body.include?(monitor.keyword)
      
      status = case monitor.keyword_type
               when 'exists'
                 keyword_found ? :up : :down
               when 'not_exists'
                 keyword_found ? :down : :up
               else
                 :down
               end

      CheckResult.new(
        monitor: monitor,
        status: status,
        response_time: response_time,
        metadata: {
          http_status: response.status,
          keyword_found: keyword_found,
          keyword: monitor.keyword
        }
      )
    rescue Faraday::Error => e
      CheckResult.new(
        monitor: monitor,
        status: :down,
        error_message: e.message
      )
    end
  end
end
```

#### 5.1.3 Ping 监控 (ICMP)

```ruby
# app/services/monitors/ping_checker.rb

module Monitors
  class PingChecker < BaseChecker
    def check
      ping = Net::Ping::ICMP.new(monitor.hostname, nil, monitor.timeout)
      ping.ping

      CheckResult.new(
        monitor: monitor,
        status: ping.status == 'alive' ? :up : :down,
        response_time: (ping.duration * 1000).to_i,
        metadata: {
          ping_duration: ping.duration,
          host: monitor.hostname
        }
      )
    rescue => e
      CheckResult.new(
        monitor: monitor,
        status: :down,
        error_message: e.message
      )
    end
  end
end
```

#### 5.1.4 端口监控 (TCP)

```ruby
# app/services/monitors/port_checker.rb

module Monitors
  class PortChecker < BaseChecker
    def check
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      
      socket = TCPSocket.new(
        monitor.hostname,
        monitor.port,
        nil, nil,
        connect_timeout: monitor.timeout
      )
      
      response_time = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).to_i
      socket.close

      CheckResult.new(
        monitor: monitor,
        status: :up,
        response_time: response_time,
        metadata: {
          host: monitor.hostname,
          port: monitor.port
        }
      )
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Errno::EHOSTUNREACH, SocketError => e
      CheckResult.new(
        monitor: monitor,
        status: :down,
        error_message: e.message,
        metadata: {
          error_class: e.class.name,
          host: monitor.hostname,
          port: monitor.port
        }
      )
    end
  end
end
```

#### 5.1.5 心跳/Cron 监控

```ruby
# app/services/monitors/heartbeat_checker.rb

module Monitors
  class HeartbeatChecker < BaseChecker
    def check
      last_heartbeat = monitor.last_heartbeat_at
      
      if last_heartbeat.nil?
        return CheckResult.new(
          monitor: monitor,
          status: :down,
          error_message: 'No heartbeat received yet'
        )
      end

      time_since_last = Time.current - last_heartbeat
      expected_interval = monitor.heartbeat_interval.seconds
      grace_period = expected_interval * 0.1  # 10% 宽限期

      status = time_since_last <= (expected_interval + grace_period) ? :up : :down

      CheckResult.new(
        monitor: monitor,
        status: status,
        metadata: {
          last_heartbeat_at: last_heartbeat.iso8601,
          time_since_last: time_since_last.to_i,
          expected_interval: monitor.heartbeat_interval
        }
      )
    end
  end
end
```

#### 5.1.6 SSL 证书监控

```ruby
# app/services/monitors/ssl_checker.rb

module Monitors
  class SslChecker < BaseChecker
    def check
      certificate = fetch_certificate

      if certificate.nil?
        return CheckResult.new(
          monitor: monitor,
          status: :down,
          error_message: 'Unable to fetch SSL certificate'
        )
      end

      days_until_expiry = (certificate.not_after - Time.current).to_i / 1.day
      status = days_until_expiry > 0 ? :up : :down

      CheckResult.new(
        monitor: monitor,
        status: status,
        metadata: {
          subject: certificate.subject.to_s,
          issuer: certificate.issuer.to_s,
          not_before: certificate.not_before.iso8601,
          not_after: certificate.not_after.iso8601,
          days_until_expiry: days_until_expiry,
          serial: certificate.serial.to_s
        }
      )
    rescue => e
      CheckResult.new(
        monitor: monitor,
        status: :down,
        error_message: e.message
      )
    end

    private

    def fetch_certificate
      uri = URI.parse("https://#{monitor.hostname}")
      
      tcp = TCPSocket.new(uri.host, uri.port || 443)
      ssl = OpenSSL::SSL::SSLSocket.new(tcp)
      ssl.connect
      
      cert = ssl.peer_cert
      ssl.close
      tcp.close
      
      cert
    rescue => e
      nil
    end
  end
end
```

#### 5.1.7 域名过期监控

```ruby
# app/services/monitors/domain_checker.rb

module Monitors
  class DomainChecker < BaseChecker
    def check
      whois = Whois.whois(monitor.hostname)
      parser = Whois::Parser.new(whois)
      
      expiry_date = parser.expires_on
      
      if expiry_date.nil?
        return CheckResult.new(
          monitor: monitor,
          status: :down,
          error_message: 'Unable to determine domain expiry date'
        )
      end

      days_until_expiry = (expiry_date - Time.current).to_i / 1.day
      status = days_until_expiry > 0 ? :up : :down

      CheckResult.new(
        monitor: monitor,
        status: status,
        metadata: {
          registrar: parser.registrar&.name,
          created_on: parser.created_on&.iso8601,
          updated_on: parser.updated_on&.iso8601,
          expires_on: expiry_date.iso8601,
          days_until_expiry: days_until_expiry
        }
      )
    rescue => e
      CheckResult.new(
        monitor: monitor,
        status: :down,
        error_message: e.message
      )
    end
  end
end
```

#### 5.1.8 DNS 监控

```ruby
# app/services/monitors/dns_checker.rb

module Monitors
  class DnsChecker < BaseChecker
    def check
      resolver = Resolv::DNS.new
      records = resolver.getresources(
        monitor.hostname,
        record_class
      )
      
      values = records.map(&:value).map(&:to_s)
      expected = monitor.dns_expected_value
      
      status = if expected.present?
                 values.include?(expected) ? :up : :down
               else
                 values.any? ? :up : :down
               end

      CheckResult.new(
        monitor: monitor,
        status: status,
        metadata: {
          record_type: monitor.dns_record_type,
          values: values,
          expected_value: expected
        }
      )
    rescue Resolv::ResolvError => e
      CheckResult.new(
        monitor: monitor,
        status: :down,
        error_message: e.message
      )
    end

    private

    def record_class
      case monitor.dns_record_type
      when 'A' then Resolv::DNS::Resource::IN::A
      when 'AAAA' then Resolv::DNS::Resource::IN::AAAA
      when 'CNAME' then Resolv::DNS::Resource::IN::CNAME
      when 'MX' then Resolv::DNS::Resource::IN::MX
      when 'TXT' then Resolv::DNS::Resource::IN::TXT
      else Resolv::DNS::Resource::IN::A
      end
    end
  end
end
```

#### 5.1.9 API 监控 (JSON 断言)

```ruby
# app/services/monitors/api_checker.rb

module Monitors
  class ApiChecker < BaseChecker
    def check
      response = connection.send(http_method) do |req|
        req.url monitor.url
        req.headers.merge!(custom_headers)
        req.body = monitor.http_body if monitor.http_body.present?
      end

      json = JSON.parse(response.body)
      assertions_passed = evaluate_assertions(json)

      CheckResult.new(
        monitor: monitor,
        status: assertions_passed ? :up : :down,
        response_time: response_time,
        metadata: {
          http_status: response.status,
          assertions: monitor.api_assertions,
          assertions_passed: assertions_passed
        }
      )
    rescue JSON::ParserError => e
      CheckResult.new(
        monitor: monitor,
        status: :down,
        error_message: "Invalid JSON response: #{e.message}"
      )
    rescue Faraday::Error => e
      CheckResult.new(
        monitor: monitor,
        status: :down,
        error_message: e.message
      )
    end

    private

    def evaluate_assertions(json)
      assertions = monitor.api_assertions || []
      
      assertions.all? do |assertion|
        actual = json_path(json, assertion['path'])
        compare(actual, assertion['operator'], assertion['value'])
      end
    end

    def json_path(json, path)
      # 简单的 JSONPath 实现
      # 支持 $.key.subkey 和 $.array[0] 语法
      parts = path.sub(/^\$\.?/, '').split('.')
      result = json
      
      parts.each do |part|
        if result.is_a?(Hash)
          result = result[part]
        else
          return nil
        end
      end
      
      result
    end

    def compare(actual, operator, expected)
      case operator
      when 'eq' then actual.to_s == expected.to_s
      when 'ne' then actual.to_s != expected.to_s
      when 'gt' then actual.to_f > expected.to_f
      when 'lt' then actual.to_f < expected.to_f
      when 'gte' then actual.to_f >= expected.to_f
      when 'lte' then actual.to_f <= expected.to_f
      when 'contains' then actual.to_s.include?(expected.to_s)
      when 'not_contains' then !actual.to_s.include?(expected.to_s)
      when 'exists' then !actual.nil?
      when 'not_exists' then actual.nil?
      else false
      end
    end
  end
end
```

### 5.2 基础检查器类

```ruby
# app/services/monitors/base_checker.rb

module Monitors
  class BaseChecker
    attr_reader :monitor, :start_time

    def initialize(monitor)
      @monitor = monitor
    end

    def check
      raise NotImplementedError, "#{self.class} must implement #check"
    end

    private

    def response_time
      return nil unless start_time
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).to_i
    end
  end
end
```

### 5.3 检查结果模型

```ruby
# app/models/check_result.rb

class CheckResult < ApplicationRecord
  belongs_to :monitor

  enum status: { up: 'up', down: 'down' }

  validates :status, presence: true
  validates :checked_at, presence: true

  before_validation :set_checked_at, on: :create

  scope :recent, -> { order(checked_at: :desc) }
  scope :for_period, ->(period) { where('checked_at >= ?', period.ago) }

  private

  def set_checked_at
    self.checked_at ||= Time.current
  end
end
```

### 5.4 监控调度

```ruby
# app/jobs/monitor_check_job.rb

class MonitorCheckJob < ApplicationJob
  queue_as :monitors

  # Good Job 限制并发
  good_job_control_concurrency_with(
    total_limit: 10,
    key: -> { "monitor-check-#{arguments.first}" }
  )

  def perform(monitor_id)
    monitor = Monitor.find(monitor_id)
    return if monitor.paused?

    checker = checker_for(monitor)
    result = checker.check

    ActiveRecord::Base.transaction do
      result.save!
      update_monitor_status(monitor, result)
      create_incident_if_needed(monitor, result)
      notify_if_needed(monitor, result)
    end
  end

  private

  def checker_for(monitor)
    case monitor.monitor_type
    when 'http', 'https' then Monitors::HttpChecker.new(monitor)
    when 'keyword' then Monitors::KeywordChecker.new(monitor)
    when 'ping' then Monitors::PingChecker.new(monitor)
    when 'port' then Monitors::PortChecker.new(monitor)
    when 'heartbeat' then Monitors::HeartbeatChecker.new(monitor)
    when 'ssl' then Monitors::SslChecker.new(monitor)
    when 'domain' then Monitors::DomainChecker.new(monitor)
    when 'dns' then Monitors::DnsChecker.new(monitor)
    when 'api' then Monitors::ApiChecker.new(monitor)
    else raise "Unknown monitor type: #{monitor.monitor_type}"
    end
  end

  def update_monitor_status(monitor, result)
    old_status = monitor.status
    new_status = result.status

    if old_status == new_status
      monitor.update!(
        consecutive_failures: new_status == 'down' ? monitor.consecutive_failures + 1 : 0,
        last_check_at: Time.current,
        response_time: result.response_time
      )
    else
      monitor.update!(
        status: new_status,
        consecutive_failures: new_status == 'down' ? 1 : 0,
        last_check_at: Time.current,
        last_status_change_at: Time.current,
        response_time: result.response_time
      )
    end
  end

  def create_incident_if_needed(monitor, result)
    return unless monitor.saved_change_to_status?

    if result.down?
      monitor.incidents.create!(
        status: :ongoing,
        started_at: Time.current,
        cause: result.metadata&.dig('error_class') || 'check_failed',
        cause_detail: result.error_message
      )
    elsif result.up?
      incident = monitor.incidents.ongoing.last
      if incident
        incident.update!(
          status: :resolved,
          resolved_at: Time.current,
          duration: (Time.current - incident.started_at).to_i
        )
      end
    end
  end

  def notify_if_needed(monitor, result)
    return unless monitor.saved_change_to_status?
    return unless should_notify?(monitor, result)

    incident = monitor.incidents.last
    NotificationDispatchJob.perform_later(incident.id)
  end

  def should_notify?(monitor, result)
    # 检查是否在维护窗口内
    return false if MaintenanceWindow.active.exists?

    # 检查告警延迟
    if monitor.alert_delay > 0 && result.down?
      return false if monitor.last_status_change_at.nil?
      return false if Time.current - monitor.last_status_change_at < monitor.alert_delay.seconds
    end

    # 检查连续失败次数
    if result.down?
      return monitor.consecutive_failures >= monitor.alert_threshold
    end

    true
  end
end
```

### 5.5 调度配置

```ruby
# config/schedule.rb

every 1.minute do
  runner "MonitorSchedulerJob.perform_later"
end

# 每天凌晨 3 点清理旧数据
every 1.day, at: '3:00 am' do
  runner "DataCleanupJob.perform_later"
end

# 每小时聚合响应时间数据
every 1.hour do
  runner "ResponseTimeAggregationJob.perform_later"
end
```

```ruby
# app/jobs/monitor_scheduler_job.rb

class MonitorSchedulerJob < ApplicationJob
  queue_as :scheduler

  def perform
    now = Time.current
    
    Monitor.active.find_each do |monitor|
      # 检查是否到了执行时间
      next if monitor.last_check_at.present? && 
              (now - monitor.last_check_at) < monitor.interval.seconds

      MonitorCheckJob.perform_later(monitor.id)
    end
  end
end
```

---

## 6. 告警与通知系统

### 6.1 通知渠道实现

#### 6.1.1 基础通知器

```ruby
# app/services/notifiers/base_notifier.rb

module Notifiers
  class BaseNotifier
    attr_reader :channel, :incident

    def initialize(channel, incident)
      @channel = channel
      @incident = incident
    end

    def notify
      raise NotImplementedError
    end

    private

    def monitor
      incident.monitor
    end

    def message
      if incident.ongoing?
        down_message
      else
        up_message
      end
    end

    def down_message
      <<~MSG
        🔴 Monitor Down: #{monitor.name}
        
        URL: #{monitor.url || monitor.hostname}
        Status: Down
        Started: #{incident.started_at.strftime('%Y-%m-%d %H:%M:%S UTC')}
        Cause: #{incident.cause_detail || incident.cause}
        
        Duration: #{time_ago_in_words(incident.started_at)}
      MSG
    end

    def up_message
      <<~MSG
        ✅ Monitor Up: #{monitor.name}
        
        URL: #{monitor.url || monitor.hostname}
        Status: Up
        Downtime: #{distance_of_time_in_words(incident.duration)}
        
        Incident resolved at #{incident.resolved_at.strftime('%Y-%m-%d %H:%M:%S UTC')}
      MSG
    end
  end
end
```

#### 6.1.2 Email 通知器

```ruby
# app/services/notifiers/email_notifier.rb

module Notifiers
  class EmailNotifier < BaseNotifier
    def notify
      MonitorMailer.alert(
        to: channel.config['address'],
        incident: incident,
        message: message
      ).deliver_later
      
      { success: true }
    rescue => e
      { success: false, error: e.message }
    end
  end
end
```

#### 6.1.3 Webhook 通知器（Slack/Mattermost/飞书）

```ruby
# app/services/notifiers/webhook_notifier.rb

module Notifiers
  class WebhookNotifier < BaseNotifier
    def notify
      payload = build_payload
      response = Faraday.post(channel.config['webhook_url']) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = payload.to_json
      end

      if response.success?
        { success: true }
      else
        { success: false, error: "HTTP #{response.status}: #{response.body}" }
      end
    rescue => e
      { success: false, error: e.message }
    end

    private

    def build_payload
      case channel.channel_type
      when 'slack'
        build_slack_payload
      when 'mattermost'
        build_mattermost_payload
      when 'feishu'
        build_feishu_payload
      else
        build_generic_payload
      end
    end

    def build_slack_payload
      {
        text: message,
        attachments: [{
          color: incident.ongoing? ? '#dc2626' : '#16a34a',
          fields: [
            { title: 'Monitor', value: monitor.name, short: true },
            { title: 'Status', value: incident.ongoing? ? 'Down' : 'Up', short: true },
            { title: 'URL', value: monitor.url || monitor.hostname, short: false }
          ],
          footer: 'Uptime Monitor',
          ts: Time.current.to_i
        }]
      }
    end

    def build_mattermost_payload
      {
        text: message,
        username: 'Uptime Monitor',
        icon_emoji: incident.ongoing? ? ':red_circle:' : ':green_circle:'
      }
    end

    def build_feishu_payload
      {
        msg_type: 'interactive',
        card: {
          header: {
            title: {
              tag: 'plain_text',
              content: incident.ongoing? ? '🔴 Monitor Down' : '✅ Monitor Up'
            },
            template: incident.ongoing? ? 'red' : 'green'
          },
          elements: [
            {
              tag: 'div',
              text: {
                tag: 'lark_md',
                content: "**#{monitor.name}**\n#{monitor.url || monitor.hostname}"
              }
            },
            {
              tag: 'div',
              fields: [
                { is_short: true, text: { tag: 'lark_md', content: "**Status**\n#{incident.ongoing? ? 'Down' : 'Up'}" } },
                { is_short: true, text: { tag: 'lark_md', content: "**Cause**\n#{incident.cause}" } }
              ]
            }
          ]
        }
      }
    end

    def build_generic_payload
      {
        text: message,
        monitor: {
          id: monitor.id,
          name: monitor.name,
          url: monitor.url || monitor.hostname,
          status: monitor.status
        },
        incident: {
          id: incident.id,
          status: incident.status,
          started_at: incident.started_at.iso8601,
          cause: incident.cause
        }
      }
    end
  end
end
```

### 6.2 通知分发作业

```ruby
# app/jobs/notification_dispatch_job.rb

class NotificationDispatchJob < ApplicationJob
  queue_as :notifications

  def perform(incident_id)
    incident = Incident.find(incident_id)
    monitor = incident.monitor

    monitor.notification_channels.enabled.find_each do |channel|
      result = send_notification(channel, incident)
      
      log_notification(channel, incident, result)
    end
  end

  private

  def send_notification(channel, incident)
    notifier = notifier_for(channel, incident)
    notifier.notify
  end

  def notifier_for(channel, incident)
    case channel.channel_type
    when 'email' then Notifiers::EmailNotifier.new(channel, incident)
    when 'slack', 'mattermost', 'feishu' then Notifiers::WebhookNotifier.new(channel, incident)
    else raise "Unknown channel type: #{channel.channel_type}"
    end
  end

  def log_notification(channel, incident, result)
    NotificationLog.create!(
      incident: incident,
      notification_channel: channel,
      monitor: incident.monitor,
      status: result[:success] ? 'sent' : 'failed',
      message: message_for(incident),
      error_message: result[:error],
      sent_at: Time.current
    )
    
    channel.update!(
      last_used_at: Time.current,
      last_error: result[:success] ? nil : result[:error]
    )
  end

  def message_for(incident)
    # 复用 notifier 的 message 逻辑
    notifier = Notifiers::BaseNotifier.new(nil, incident)
    notifier.send(:message)
  end
end
```

### 6.3 心跳接收端点

```ruby
# app/controllers/heartbeat_controller.rb

class HeartbeatController < ApplicationController
  skip_before_action :authenticate_user!

  # GET /heartbeat/:token
  def ping
    monitor = Monitor.find_by(heartbeat_token: params[:token])
    
    if monitor
      monitor.update!(last_heartbeat_at: Time.current)
      render json: { status: 'ok' }
    else
      render json: { error: 'Not found' }, status: :not_found
    end
  end
end
```

---

## 7. 状态页面

### 7.1 状态页面控制器

```ruby
# app/controllers/status_pages_controller.rb

class StatusPagesController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :find_status_page
  before_action :check_password, if: -> { @status_page.password_digest.present? }

  def show
    @monitors = @status_page.monitors
                            .includes(:incidents)
                            .order(sort_order: :asc)
    
    @active_announcements = @status_page.announcements
                                        .where.not(status: 'resolved')
                                        .order(started_at: :desc)
    
    @resolved_announcements = @status_page.announcements
                                          .where(status: 'resolved')
                                          .order(resolved_at: :desc)
                                          .limit(10)
  end

  private

  def find_status_page
    @status_page = StatusPage.published.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.root.join('public', '404.html'), status: :not_found
  end

  def check_password
    return if session[:status_page_auth] == @status_page.id
    
    unless params[:password].present? && 
           ActiveSupport::SecurityUtils.secure_compare(
             params[:password],
             @status_page.password
           )
      render :password_form
    else
      session[:status_page_auth] = @status_page.id
    end
  end
end
```

### 7.2 状态页面视图

```erb
<!-- app/views/status_pages/show.html.erb -->

<div class="min-h-screen bg-gray-50">
  <!-- Header -->
  <header class="bg-<%= @status_page.theme_color.delete('#') %> text-white py-8">
    <div class="max-w-4xl mx-auto px-4">
      <% if @status_page.logo_url.present? %>
        <%= image_tag @status_page.logo_url, class: "h-12 mb-4" %>
      <% end %>
      <h1 class="text-3xl font-bold"><%= @status_page.name %></h1>
    </div>
  </header>

  <!-- Overall Status -->
  <div class="max-w-4xl mx-auto px-4 -mt-4">
    <div class="bg-white rounded-lg shadow p-6 mb-8">
      <% if @monitors.all? { |m| m.status == 'up' } %>
        <div class="flex items-center text-green-600">
          <div class="w-3 h-3 bg-green-500 rounded-full mr-3"></div>
          <span class="text-lg font-semibold">All Systems Operational</span>
        </div>
      <% elsif @monitors.any? { |m| m.status == 'down' } %>
        <div class="flex items-center text-red-600">
          <div class="w-3 h-3 bg-red-500 rounded-full mr-3"></div>
          <span class="text-lg font-semibold">Some Systems Experiencing Issues</span>
        </div>
      <% else %>
        <div class="flex items-center text-yellow-600">
          <div class="w-3 h-3 bg-yellow-500 rounded-full mr-3"></div>
          <span class="text-lg font-semibold">Degraded Performance</span>
        </div>
      <% end %>
    </div>
  </div>

  <!-- Active Incidents -->
  <% if @active_announcements.any? %>
    <div class="max-w-4xl mx-auto px-4 mb-8">
      <h2 class="text-xl font-semibold mb-4">Active Incidents</h2>
      <% @active_announcements.each do |announcement| %>
        <div class="bg-white rounded-lg shadow p-6 mb-4 border-l-4 border-yellow-500">
          <div class="flex justify-between items-start mb-2">
            <h3 class="text-lg font-semibold"><%= announcement.title %></h3>
            <span class="px-3 py-1 text-sm rounded-full 
              <%= case announcement.status
                  when 'investigating' then 'bg-yellow-100 text-yellow-800'
                  when 'identified' then 'bg-orange-100 text-orange-800'
                  when 'monitoring' then 'bg-blue-100 text-blue-800'
                  end %>">
              <%= announcement.status.capitalize %>
            </span>
          </div>
          <p class="text-gray-600 mb-4"><%= announcement.content %></p>
          <div class="text-sm text-gray-500">
            Started <%= time_ago_in_words(announcement.started_at) %> ago
          </div>
          
          <% if announcement.updates.any? %>
            <div class="mt-4 pt-4 border-t">
              <% announcement.updates.order(created_at: :desc).each do |update| %>
                <div class="mb-3">
                  <div class="text-sm text-gray-500">
                    <%= update.created_at.strftime('%b %d, %H:%M UTC') %>
                  </div>
                  <p class="text-gray-700"><%= update.content %></p>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
  <% end %>

  <!-- Monitors -->
  <div class="max-w-4xl mx-auto px-4 mb-8">
    <h2 class="text-xl font-semibold mb-4">Services</h2>
    
    <% @status_page.monitor_groups.each do |group| %>
      <div class="mb-6">
        <h3 class="text-lg font-medium text-gray-700 mb-3"><%= group.name %></h3>
        <div class="bg-white rounded-lg shadow overflow-hidden">
          <% group.monitors.each do |monitor| %>
            <div class="flex items-center justify-between p-4 border-b last:border-0">
              <div class="flex items-center">
                <div class="w-3 h-3 rounded-full mr-3
                  <%= case monitor.status
                      when 'up' then 'bg-green-500'
                      when 'down' then 'bg-red-500'
                      else 'bg-gray-400'
                      end %>">
                </div>
                <span class="font-medium"><%= monitor.name %></span>
              </div>
              
              <div class="flex items-center space-x-4">
                <% if @status_page.show_uptime_percentage? %>
                  <span class="text-sm text-gray-500">
                    <%= monitor.uptime_24h || '100' %>% uptime
                  </span>
                <% end %>
                
                <% if @status_page.show_response_time_graph? %>
                  <div class="w-32">
                    <!-- Mini sparkline chart -->
                    <%= render 'response_time_sparkline', monitor: monitor %>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
  </div>

  <!-- Past Incidents -->
  <% if @resolved_announcements.any? %>
    <div class="max-w-4xl mx-auto px-4 mb-8">
      <h2 class="text-xl font-semibold mb-4">Past Incidents</h2>
      <% @resolved_announcements.each do |announcement| %>
        <div class="bg-white rounded-lg shadow p-6 mb-4">
          <div class="flex justify-between items-start mb-2">
            <h3 class="text-lg font-semibold"><%= announcement.title %></h3>
            <span class="text-sm text-gray-500">
              <%= announcement.resolved_at.strftime('%b %d, %Y') %>
            </span>
          </div>
          <p class="text-gray-600"><%= announcement.content %></p>
        </div>
      <% end %>
    </div>
  <% end %>

  <!-- Footer -->
  <footer class="max-w-4xl mx-auto px-4 py-8 text-center text-gray-500 text-sm">
    Powered by Uptime Monitor
  </footer>
</div>
```

### 7.3 Uptime 计算任务

```ruby
# app/jobs/uptime_calculation_job.rb

class UptimeCalculationJob < ApplicationJob
  queue_as :maintenance

  def perform
    Monitor.active.find_each do |monitor|
      calculate_uptime(monitor)
    end
  end

  private

  def calculate_uptime(monitor)
    # 计算 24 小时 uptime
    incidents_24h = monitor.incidents
                           .where('started_at >= ?', 24.hours.ago)
                           .where(status: 'resolved')
    
    downtime_24h = incidents_24h.sum(:duration) || 0
    uptime_24h = ((24.hours - downtime_24h) / 24.hours * 100).round(2)

    # 计算 7 天 uptime
    incidents_7d = monitor.incidents
                          .where('started_at >= ?', 7.days.ago)
                          .where(status: 'resolved')
    
    downtime_7d = incidents_7d.sum(:duration) || 0
    uptime_7d = ((7.days - downtime_7d) / 7.days * 100).round(2)

    # 计算 30 天 uptime
    incidents_30d = monitor.incidents
                           .where('started_at >= ?', 30.days.ago)
                           .where(status: 'resolved')
    
    downtime_30d = incidents_30d.sum(:duration) || 0
    uptime_30d = ((30.days - downtime_30d) / 30.days * 100).round(2)

    monitor.update!(
      uptime_24h: uptime_24h,
      uptime_7d: uptime_7d,
      uptime_30d: uptime_30d
    )
  end
end
```

---

## 8. 事件管理

### 8.1 事件控制器

```ruby
# app/controllers/incidents_controller.rb

class IncidentsController < ApplicationController
  before_action :set_incident, only: [:show, :update]

  def index
    @incidents = Incident.includes(:monitor)
                         .order(started_at: :desc)
                         .page(params[:page])

    # 过滤
    @incidents = @incidents.where(status: params[:status]) if params[:status].present?
    @incidents = @incidents.where(monitor_id: params[:monitor_id]) if params[:monitor_id].present?
    @incidents = @incidents.where('started_at >= ?', params[:from].to_datetime) if params[:from].present?
    @incidents = @incidents.where('started_at <= ?', params[:to].to_datetime) if params[:to].present?
  end

  def show
    @comments = @incident.comments.order(created_at: :asc)
  end

  def update
    if @incident.update(incident_params)
      redirect_to @incident, notice: 'Incident updated.'
    else
      render :show
    end
  end

  private

  def set_incident
    @incident = Incident.find(params[:id])
  end

  def incident_params
    params.require(:incident).permit(:cause, :cause_detail, :excluded_from_report, tags: [])
  end
end
```

### 8.2 事件评论

```ruby
# app/controllers/incident_comments_controller.rb

class IncidentCommentsController < ApplicationController
  before_action :set_incident

  def create
    @comment = @incident.comments.build(comment_params)
    
    if @comment.save
      redirect_to @incident, notice: 'Comment added.'
    else
      render 'incidents/show'
    end
  end

  def update
    @comment = @incident.comments.find(params[:id])
    
    if @comment.update(comment_params)
      redirect_to @incident, notice: 'Comment updated.'
    else
      render 'incidents/show'
    end
  end

  def destroy
    @comment = @incident.comments.find(params[:id])
    @comment.destroy
    
    redirect_to @incident, notice: 'Comment deleted.'
  end

  private

  def set_incident
    @incident = Incident.find(params[:incident_id])
  end

  def comment_params
    params.require(:incident_comment).permit(:content)
  end
end
```

### 8.3 事件导出

```ruby
# app/controllers/incidents_controller.rb (添加)

def export
  @incidents = Incident.includes(:monitor)
  
  # 过滤
  @incidents = @incidents.where(monitor_id: params[:monitor_id]) if params[:monitor_id].present?
  @incidents = @incidents.where('started_at >= ?', params[:from].to_datetime) if params[:from].present?
  @incidents = @incidents.where('started_at <= ?', params[:to].to_datetime) if params[:to].present?

  respond_to do |format|
    format.csv do
      headers['Content-Disposition'] = "attachment; filename=incidents-#{Date.current}.csv"
      headers['Content-Type'] = 'text/csv'
    end
  end
end
```

```erb
<!-- app/views/incidents/export.csv.erb -->

Monitor,Status,Started At,Resolved At,Duration,Cause,Detail
<% @incidents.each do |incident| %>
<%= incident.monitor.name %>,<%= incident.status %>,<%= incident.started_at.iso8601 %>,<%= incident.resolved_at&.iso8601 %>,<%= incident.duration %>,<%= incident.cause %>,<%= incident.cause_detail %>
<% end %>
```

---

## 9. 用户界面设计

### 9.1 仪表盘布局

```erb
<!-- app/views/layouts/dashboard.html.erb -->

<!DOCTYPE html>
<html>
<head>
  <title>Uptime Monitor</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= stylesheet_link_tag "tailwind", "inter-font", "data-turbo-track": "reload" %>
  <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
  <%= javascript_importmap_tags %>
</head>

<body class="bg-gray-100">
  <div class="min-h-screen flex">
    <!-- Sidebar -->
    <aside class="w-64 bg-gray-900 text-white">
      <div class="p-4">
        <h1 class="text-xl font-bold">Uptime Monitor</h1>
      </div>
      
      <nav class="mt-4">
        <%= link_to root_path, class: "flex items-center px-4 py-3 hover:bg-gray-800 #{'bg-gray-800' if controller_name == 'dashboard'}" do %>
          <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"></path>
          </svg>
          Dashboard
        <% end %>
        
        <%= link_to monitors_path, class: "flex items-center px-4 py-3 hover:bg-gray-800 #{'bg-gray-800' if controller_name == 'monitors'}" do %>
          <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
          </svg>
          Monitors
        <% end %>
        
        <%= link_to incidents_path, class: "flex items-center px-4 py-3 hover:bg-gray-800 #{'bg-gray-800' if controller_name == 'incidents'}" do %>
          <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          Incidents
        <% end %>
        
        <%= link_to status_pages_path, class: "flex items-center px-4 py-3 hover:bg-gray-800 #{'bg-gray-800' if controller_name == 'status_pages'}" do %>
          <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9"></path>
          </svg>
          Status Pages
        <% end %>
        
        <%= link_to notification_channels_path, class: "flex items-center px-4 py-3 hover:bg-gray-800 #{'bg-gray-800' if controller_name == 'notification_channels'}" do %>
          <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"></path>
          </svg>
          Notifications
        <% end %>
        
        <%= link_to maintenance_windows_path, class: "flex items-center px-4 py-3 hover:bg-gray-800 #{'bg-gray-800' if controller_name == 'maintenance_windows'}" do %>
          <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          Maintenance
        <% end %>
      </nav>
    </aside>

    <!-- Main Content -->
    <main class="flex-1">
      <!-- Top Bar -->
      <header class="bg-white shadow">
        <div class="flex items-center justify-between px-6 py-4">
          <div>
            <%= yield :header %>
          </div>
          
          <div class="flex items-center space-x-4">
            <div class="flex items-center space-x-2">
              <div class="w-3 h-3 bg-green-500 rounded-full"></div>
              <span class="text-sm text-gray-600">
                <%= Monitor.active.up.count %> / <%= Monitor.active.count %> monitors up
              </span>
            </div>
            
            <div class="relative" data-controller="dropdown">
              <button data-action="click->dropdown#toggle" class="flex items-center space-x-2">
                <span><%= current_user.name || current_user.email %></span>
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                </svg>
              </button>
              
              <div data-dropdown-target="menu" class="hidden absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg">
                <%= link_to "Settings", edit_user_path(current_user), class: "block px-4 py-2 hover:bg-gray-100" %>
                <%= link_to "API Keys", api_keys_path, class: "block px-4 py-2 hover:bg-gray-100" %>
                <%= link_to "Sign Out", session_path, method: :delete, class: "block px-4 py-2 hover:bg-gray-100" %>
              </div>
            </div>
          </div>
        </div>
      </header>

      <!-- Page Content -->
      <div class="p-6">
        <% if notice %>
          <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
            <%= notice %>
          </div>
        <% end %>
        
        <% if alert %>
          <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            <%= alert %>
          </div>
        <% end %>
        
        <%= yield %>
      </div>
    </main>
  </div>
</body>
</html>
```

### 9.2 仪表盘首页

```erb
<!-- app/views/dashboard/show.html.erb -->

<% content_for :header do %>
  <h2 class="text-2xl font-semibold">Dashboard</h2>
<% end %>

<!-- Status Summary -->
<div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
  <div class="bg-white rounded-lg shadow p-6">
    <div class="flex items-center">
      <div class="p-3 bg-green-100 rounded-full">
        <svg class="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
        </svg>
      </div>
      <div class="ml-4">
        <p class="text-sm text-gray-500">Monitors Up</p>
        <p class="text-2xl font-semibold"><%= @monitors_up %></p>
      </div>
    </div>
  </div>
  
  <div class="bg-white rounded-lg shadow p-6">
    <div class="flex items-center">
      <div class="p-3 bg-red-100 rounded-full">
        <svg class="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
        </svg>
      </div>
      <div class="ml-4">
        <p class="text-sm text-gray-500">Monitors Down</p>
        <p class="text-2xl font-semibold"><%= @monitors_down %></p>
      </div>
    </div>
  </div>
  
  <div class="bg-white rounded-lg shadow p-6">
    <div class="flex items-center">
      <div class="p-3 bg-yellow-100 rounded-full">
        <svg class="w-6 h-6 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
        </svg>
      </div>
      <div class="ml-4">
        <p class="text-sm text-gray-500">Active Incidents</p>
        <p class="text-2xl font-semibold"><%= @active_incidents_count %></p>
      </div>
    </div>
  </div>
  
  <div class="bg-white rounded-lg shadow p-6">
    <div class="flex items-center">
      <div class="p-3 bg-blue-100 rounded-full">
        <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
        </svg>
      </div>
      <div class="ml-4">
        <p class="text-sm text-gray-500">Overall Uptime</p>
        <p class="text-2xl font-semibold"><%= @overall_uptime %>%</p>
      </div>
    </div>
  </div>
</div>

<!-- Monitors Grid -->
<div class="mb-8">
  <div class="flex items-center justify-between mb-4">
    <h3 class="text-lg font-semibold">Monitors</h3>
    <div class="flex space-x-2">
      <button data-controller="view-toggle" data-action="click->view-toggle#grid" 
              class="px-3 py-1 rounded bg-gray-200">
        Grid
      </button>
      <button data-controller="view-toggle" data-action="click->view-toggle#list"
              class="px-3 py-1 rounded">
        List
      </button>
    </div>
  </div>
  
  <div id="monitors" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
    <% @monitors.each do |monitor| %>
      <%= render 'monitor_card', monitor: monitor %>
    <% end %>
  </div>
</div>

<!-- Recent Incidents -->
<div>
  <h3 class="text-lg font-semibold mb-4">Recent Incidents</h3>
  
  <% if @recent_incidents.any? %>
    <div class="bg-white rounded-lg shadow overflow-hidden">
      <% @recent_incidents.each do |incident| %>
        <div class="p-4 border-b last:border-0">
          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <div class="w-3 h-3 rounded-full mr-3
                <%= incident.ongoing? ? 'bg-red-500' : 'bg-green-500' %>">
              </div>
              <div>
                <p class="font-medium"><%= incident.monitor.name %></p>
                <p class="text-sm text-gray-500">
                  <%= incident.cause_detail || incident.cause %>
                </p>
              </div>
            </div>
            <div class="text-right">
              <p class="text-sm text-gray-500">
                <%= time_ago_in_words(incident.started_at) %> ago
              </p>
              <% if incident.resolved? %>
                <p class="text-xs text-green-600">
                  Resolved in <%= distance_of_time_in_words(incident.duration) %>
                </p>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    </div>
  <% else %>
    <div class="bg-white rounded-lg shadow p-8 text-center text-gray-500">
      No recent incidents
    </div>
  <% end %>
</div>
```

### 9.3 监控器卡片组件

```erb
<!-- app/views/dashboard/_monitor_card.html.erb -->

<div class="bg-white rounded-lg shadow hover:shadow-md transition-shadow">
  <div class="p-4">
    <div class="flex items-center justify-between mb-3">
      <div class="flex items-center">
        <div class="w-3 h-3 rounded-full mr-2
          <%= case monitor.status
              when 'up' then 'bg-green-500'
              when 'down' then 'bg-red-500'
              when 'pending' then 'bg-yellow-500'
              else 'bg-gray-400'
              end %>">
        </div>
        <h4 class="font-medium truncate"><%= monitor.name %></h4>
      </div>
      
      <div class="relative" data-controller="dropdown">
        <button data-action="click->dropdown#toggle" class="text-gray-400 hover:text-gray-600">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z"></path>
          </svg>
        </button>
        
        <div data-dropdown-target="menu" class="hidden absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg z-10">
          <%= link_to "Edit", edit_monitor_path(monitor), class: "block px-4 py-2 hover:bg-gray-100" %>
          <%= link_to "View Details", monitor_path(monitor), class: "block px-4 py-2 hover:bg-gray-100" %>
          <hr>
          <% if monitor.paused? %>
            <%= button_to "Resume", resume_monitor_path(monitor), method: :post, class: "block w-full text-left px-4 py-2 hover:bg-gray-100" %>
          <% else %>
            <%= button_to "Pause", pause_monitor_path(monitor), method: :post, class: "block w-full text-left px-4 py-2 hover:bg-gray-100" %>
          <% end %>
          <%= button_to "Delete", monitor_path(monitor), method: :delete, data: { confirm: "Are you sure?" }, class: "block w-full text-left px-4 py-2 hover:bg-gray-100 text-red-600" %>
        </div>
      </div>
    </div>
    
    <p class="text-sm text-gray-500 mb-3 truncate">
      <%= monitor.url || monitor.hostname %>
    </p>
    
    <div class="flex items-center justify-between text-sm">
      <span class="text-gray-500">
        <%= monitor.monitor_type.upcase %>
      </span>
      
      <% if monitor.response_time %>
        <span class="text-gray-500">
          <%= monitor.response_time %>ms
        </span>
      <% end %>
    </div>
    
    <!-- Uptime Bar -->
    <div class="mt-3">
      <div class="flex items-center justify-between text-xs text-gray-500 mb-1">
        <span>24h Uptime</span>
        <span><%= monitor.uptime_24h || '100.00' %>%</span>
      </div>
      <div class="h-2 bg-gray-200 rounded-full overflow-hidden">
        <div class="h-full rounded-full
          <%= (monitor.uptime_24h || 100) >= 99 ? 'bg-green-500' : 
              (monitor.uptime_24h || 100) >= 95 ? 'bg-yellow-500' : 'bg-red-500' %>"
             style="width: <%= monitor.uptime_24h || 100 %>%">
        </div>
      </div>
    </div>
    
    <!-- Response Time Sparkline -->
    <div class="mt-3 h-10">
      <canvas data-controller="sparkline" 
              data-sparkline-monitor-id-value="<%= monitor.id %>"
              data-sparkline-url-value="<%= response_time_chart_monitor_path(monitor) %>">
      </canvas>
    </div>
  </div>
</div>
```

### 9.4 响应时间图表

```javascript
// app/javascript/controllers/response_time_chart_controller.js

import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

export default class extends Controller {
  static values = { monitorId: Number }

  connect() {
    this.loadChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  async loadChart() {
    const response = await fetch(`/monitors/${this.monitorIdValue}/response_time_stats`)
    const data = await response.json()

    this.chart = new Chart(this.element, {
      type: 'line',
      data: {
        labels: data.labels,
        datasets: [{
          label: 'Response Time (ms)',
          data: data.values,
          borderColor: 'rgb(59, 130, 246)',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          fill: true,
          tension: 0.4,
          pointRadius: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            mode: 'index',
            intersect: false,
            callbacks: {
              label: function(context) {
                return `${context.parsed.y}ms`
              }
            }
          }
        },
        scales: {
          x: {
            display: true,
            grid: {
              display: false
            }
          },
          y: {
            display: true,
            grid: {
              color: 'rgba(0, 0, 0, 0.1)'
            },
            ticks: {
              callback: function(value) {
                return value + 'ms'
              }
            }
          }
        }
      }
    })
  }
}
```

---

## 10. Docker 部署

### 10.1 Dockerfile

```dockerfile
# Dockerfile

# Stage 1: Build
FROM ruby:3.3-slim AS builder

# 安装依赖
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    nodejs \
    npm \
    git \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装 Yarn
RUN npm install -g yarn

WORKDIR /app

# 安装 Ruby 依赖
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# 安装 JS 依赖
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# 复制源代码
COPY . .

# 预编译资产
RUN SECRET_KEY_BASE=dummy bundle exec rails assets:precompile

# 清理
RUN rm -rf node_modules tmp/cache vendor/bundle/ruby/*/cache

# Stage 2: Production
FROM ruby:3.3-slim AS production

# 安装运行时依赖
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    libpq5 \
    openssl \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 安装 Node.js (用于 SSR)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# 创建应用用户
RUN groupadd -r app && useradd -r -g app -d /app -s /sbin/nologin app

WORKDIR /app

# 从 builder 阶段复制
COPY --from=builder --chown=app:app /app /app

# 设置环境变量
ENV RAILS_ENV=production \
    RACK_ENV=production \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# 启动命令
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

### 10.2 Docker Compose

```yaml
# docker-compose.yml

version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: uptime-monitor-app
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - RAILS_ENV=production
      - RAILS_MASTER_KEY=${RAILS_MASTER_KEY}
      - DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@db:5432/uptime_monitor
      - REDIS_URL=redis://redis:6379/0
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_PORT=${SMTP_PORT}
      - SMTP_USERNAME=${SMTP_USERNAME}
      - SMTP_PASSWORD=${SMTP_PASSWORD}
      - SMTP_FROM=${SMTP_FROM}
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - uploads:/app/public/uploads
      - storage:/app/storage
    networks:
      - uptime-network

  db:
    image: postgres:16-alpine
    container_name: uptime-monitor-db
    restart: unless-stopped
    environment:
      - POSTGRES_DB=uptime_monitor
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - uptime-network

  redis:
    image: redis:7-alpine
    container_name: uptime-monitor-redis
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - uptime-network

  nginx:
    image: nginx:alpine
    container_name: uptime-monitor-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./nginx/logs:/var/log/nginx
    depends_on:
      - app
    networks:
      - uptime-network

  # Good Job worker (可选，如果需要独立 worker)
  worker:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: uptime-monitor-worker
    restart: unless-stopped
    command: bundle exec good_job start
    environment:
      - RAILS_ENV=production
      - RAILS_MASTER_KEY=${RAILS_MASTER_KEY}
      - DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@db:5432/uptime_monitor
      - GOOD_JOB_QUEUES=monitors:5;notifications:3;default:2;maintenance:1
    depends_on:
      db:
        condition: service_healthy
    networks:
      - uptime-network

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
  uploads:
    driver: local
  storage:
    driver: local

networks:
  uptime-network:
    driver: bridge
```

### 10.3 Nginx 配置

```nginx
# nginx/nginx.conf

worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
    multi_accept on;
}

http {
    # 基础配置
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    
    # MIME 类型
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # 日志
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    # Gzip
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;
    
    # SSL 配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # 上游配置
    upstream app {
        server app:3000;
    }
    
    # HTTP 重定向到 HTTPS
    server {
        listen 80;
        server_name _;
        
        location / {
            return 301 https://$host$request_uri;
        }
        
        # Let's Encrypt 验证
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
    }
    
    # HTTPS 配置
    server {
        listen 443 ssl http2;
        server_name ${DOMAIN};
        
        # SSL 证书
        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;
        
        # 安全头
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy "default-src 'self' http: https: ws: wss: data: blob: 'unsafe-inline'; frame-ancestors 'self';" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        
        # 根目录
        root /app/public;
        
        # 请求大小限制
        client_max_body_size 10M;
        
        # 代理到 Rails 应用
        location / {
            try_files $uri $uri/index.html $uri.html @app;
        }
        
        location @app {
            proxy_pass http://app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            
            # WebSocket 支持 (ActionCable)
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            
            # 超时配置
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }
        
        # 静态文件缓存
        location ~ ^/assets/ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            try_files $uri =404;
        }
        
        location ~ ^/packs/ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            try_files $uri =404;
        }
        
        # 上传文件
        location /uploads/ {
            expires 30d;
            add_header Cache-Control "public";
            try_files $uri =404;
        }
        
        # 禁止访问隐藏文件
        location ~ /\. {
            deny all;
            access_log off;
            log_not_found off;
        }
        
        # Favicon
        location = /favicon.ico {
            access_log off;
            log_not_found off;
        }
        
        # Robots.txt
        location = /robots.txt {
            access_log off;
            log_not_found off;
        }
    }
}
```

### 10.4 环境变量配置

```bash
# .env.example

# 应用配置
RAILS_ENV=production
RAILS_MASTER_KEY=your_master_key_here
DOMAIN=uptime.example.com

# 数据库配置
POSTGRES_PASSWORD=your_secure_password_here

# SMTP 配置
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password
SMTP_FROM=Uptime Monitor <noreply@example.com>

# 可选配置
# REDIS_URL=redis://localhost:6379/0
# SENTRY_DSN=https://your-sentry-dsn
```

### 10.5 部署脚本

```bash
#!/bin/bash
# deploy.sh

set -e

echo "🚀 Starting deployment..."

# 检查环境变量
if [ ! -f .env ]; then
    echo "❌ .env file not found. Please copy .env.example to .env and configure it."
    exit 1
fi

# 加载环境变量
source .env

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# 创建必要的目录
mkdir -p nginx/ssl nginx/logs

# 检查 SSL 证书
if [ ! -f nginx/ssl/fullchain.pem ] || [ ! -f nginx/ssl/privkey.pem ]; then
    echo "⚠️  SSL certificates not found."
    echo "   For development, you can use self-signed certificates:"
    echo "   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout nginx/ssl/privkey.pem -out nginx/ssl/fullchain.pem"
    echo ""
    echo "   For production, use Let's Encrypt or your own certificates."
    read -p "Continue without SSL? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 拉取最新代码
echo "📦 Pulling latest code..."
git pull origin main

# 构建镜像
echo "🔨 Building Docker images..."
docker-compose build --no-cache

# 停止旧容器
echo "⏹️  Stopping old containers..."
docker-compose down

# 启动新容器
echo "▶️  Starting new containers..."
docker-compose up -d

# 等待数据库就绪
echo "⏳ Waiting for database to be ready..."
sleep 10

# 运行数据库迁移
echo "🗄️  Running database migrations..."
docker-compose exec app rails db:create db:migrate

# 预编译资产
echo "🎨 Precompiling assets..."
docker-compose exec app rails assets:precompile

# 重启应用
echo "🔄 Restarting application..."
docker-compose restart app

# 健康检查
echo "🏥 Performing health check..."
sleep 5
if curl -f -s http://localhost:3000/health > /dev/null; then
    echo "✅ Deployment successful!"
    echo ""
    echo "Application is running at: https://${DOMAIN}"
    echo ""
    echo "Useful commands:"
    echo "  docker-compose logs -f app    # View application logs"
    echo "  docker-compose logs -f worker # View worker logs"
    echo "  docker-compose exec app rails console  # Rails console"
    echo "  docker-compose exec app rails db:migrate  # Run migrations"
else
    echo "❌ Health check failed. Please check the logs:"
    echo "  docker-compose logs app"
    exit 1
fi
```

### 10.6 初始化脚本

```bash
#!/bin/bash
# setup.sh

set -e

echo "🚀 Initial setup for Uptime Monitor..."

# 检查环境变量
if [ ! -f .env ]; then
    echo "📝 Creating .env file from example..."
    cp .env.example .env
    
    # 生成随机密码
    POSTGRES_PASSWORD=$(openssl rand -base64 32)
    RAILS_MASTER_KEY=$(bundle exec rails secret)
    
    # 更新 .env 文件
    sed -i '' "s/your_secure_password_here/$POSTGRES_PASSWORD/" .env
    sed -i '' "s/your_master_key_here/$RAILS_MASTER_KEY/" .env
    
    echo "✅ .env file created with random credentials"
    echo "   Please update SMTP settings and DOMAIN in .env"
fi

# 创建必要的目录
mkdir -p nginx/ssl nginx/logs

# 生成自签名证书（开发用）
if [ ! -f nginx/ssl/fullchain.pem ]; then
    echo "🔐 Generating self-signed SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout nginx/ssl/privkey.pem \
        -out nginx/ssl/fullchain.pem \
        -subj "/C=CN/ST=State/L=City/O=Organization/CN=localhost"
    echo "✅ Self-signed certificate generated"
fi

# 构建并启动服务
echo "🔨 Building and starting services..."
docker-compose up -d --build

# 等待数据库就绪
echo "⏳ Waiting for database..."
sleep 15

# 创建数据库并运行迁移
echo "🗄️  Setting up database..."
docker-compose exec app rails db:create db:migrate

# 创建管理员账号
echo "👤 Creating admin user..."
docker-compose exec app rails runner "
user = User.find_or_create_by!(email: 'admin@example.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.name = 'Admin'
end
puts 'Admin user created: admin@example.com / password123'
"

# 预编译资产
echo "🎨 Precompiling assets..."
docker-compose exec app rails assets:precompile

# 重启服务
echo "🔄 Restarting services..."
docker-compose restart

echo ""
echo "✅ Setup complete!"
echo ""
echo "Access your Uptime Monitor at: https://localhost"
echo ""
echo "Default admin credentials:"
echo "  Email: admin@example.com"
echo "  Password: password123"
echo ""
echo "⚠️  Please change the default password after first login!"
echo ""
echo "Useful commands:"
echo "  docker-compose logs -f        # View all logs"
echo "  docker-compose exec app rails console  # Rails console"
echo "  docker-compose down           # Stop all services"
echo "  docker-compose up -d          # Start all services"
```

### 10.7 备份脚本

```bash
#!/bin/bash
# backup.sh

set -e

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/uptime_monitor_$TIMESTAMP.sql"

# 创建备份目录
mkdir -p $BACKUP_DIR

# 加载环境变量
source .env

# 备份数据库
echo "📦 Backing up database..."
docker-compose exec -T db pg_dump -U postgres uptime_monitor > $BACKUP_FILE

# 压缩备份
gzip $BACKUP_FILE

echo "✅ Backup completed: ${BACKUP_FILE}.gz"

# 清理旧备份（保留最近 7 天）
echo "🧹 Cleaning old backups..."
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "✅ Cleanup completed"

# 可选：上传到 S3
# if [ ! -z "$AWS_S3_BUCKET" ]; then
#     echo "☁️  Uploading to S3..."
#     aws s3 cp "${BACKUP_FILE}.gz" "s3://$AWS_S3_BUCKET/backups/"
#     echo "✅ Upload completed"
# fi
```

### 10.8 恢复脚本

```bash
#!/bin/bash
# restore.sh

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file.sql.gz>"
    echo ""
    echo "Available backups:"
    ls -lh ./backups/*.sql.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE=$1

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "⚠️  WARNING: This will replace the current database!"
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# 加载环境变量
source .env

# 停止应用
echo "⏹️  Stopping application..."
docker-compose stop app worker

# 恢复数据库
echo "📦 Restoring database..."
gunzip -c $BACKUP_FILE | docker-compose exec -T db psql -U postgres uptime_monitor

# 启动应用
echo "▶️  Starting application..."
docker-compose start app worker

echo "✅ Restore completed!"
```

---

## 11. 开发计划

### 11.1 Phase 1: 基础框架 (Week 1-2)

#### 目标
- 搭建 Rails 8 项目骨架
- 实现用户认证系统
- 建立数据库基础结构
- 配置开发环境

#### 任务清单

**Day 1-2: 项目初始化**
- [ ] 创建 Rails 8 项目
- [ ] 配置 PostgreSQL
- [ ] 配置 Hotwire (Turbo + Stimulus)
- [ ] 配置 Tailwind CSS
- [ ] 设置 Good Job
- [ ] 配置 Whenever
- [ ] 创建 Docker 开发环境

**Day 3-4: 用户系统**
- [ ] 实现 User 模型
- [ ] 实现会话管理（登录/登出）
- [ ] 实现密码加密
- [ ] 创建登录页面
- [ ] 添加认证中间件
- [ ] 实现 ApiKey 模型

**Day 5-7: 数据库设计**
- [ ] 创建所有数据库迁移
- [ ] 实现模型关联
- [ ] 添加数据库索引
- [ ] 创建种子数据
- [ ] 编写模型测试

**Day 8-10: 基础 UI**
- [ ] 创建布局模板（侧边栏 + 主内容区）
- [ ] 实现仪表盘首页
- [ ] 添加导航菜单
- [ ] 配置 Turbo Frames
- [ ] 添加基础 Stimulus 控制器

#### 交付物
- 可运行的 Rails 8 应用
- 完整的用户认证系统
- 数据库 schema 设计文档
- Docker 开发环境

---

### 11.2 Phase 2: 监控核心 (Week 3-4)

#### 目标
- 实现监控器 CRUD
- 实现核心监控检查器
- 建立任务调度系统
- 实现状态管理

#### 任务清单

**Day 1-3: 监控器管理**
- [ ] 实现 Monitor 模型
- [ ] 创建监控器表单（支持所有类型）
- [ ] 实现监控器列表/网格视图
- [ ] 添加监控器分组功能
- [ ] 实现标签系统
- [ ] 添加批量操作

**Day 4-6: 监控检查器**
- [ ] 实现 HTTP/HTTPS Checker
- [ ] 实现关键词 Checker
- [ ] 实现 Ping Checker
- [ ] 实现端口 Checker
- [ ] 实现 SSL Checker
- [ ] 实现 DNS Checker
- [ ] 编写 Checker 测试

**Day 7-8: 任务调度**
- [ ] 配置 Good Job
- [ ] 实现 MonitorSchedulerJob
- [ ] 实现 MonitorCheckJob
- [ ] 添加并发控制
- [ ] 实现重试机制

**Day 9-10: 状态管理**
- [ ] 实现状态机（up/down/pending）
- [ ] 实现连续失败计数
- [ ] 实现告警阈值
- [ ] 添加状态变更日志

#### 交付物
- 完整的监控器管理功能
- 6 种核心监控检查器
- 任务调度系统
- 状态管理系统

---

### 11.3 Phase 3: 告警与通知 (Week 5-6)

#### 目标
- 实现事件管理系统
- 实现通知渠道
- 实现告警分发
- 添加心跳监控

#### 任务清单

**Day 1-3: 事件管理**
- [ ] 实现 Incident 模型
- [ ] 创建事件列表页面
- [ ] 实现事件详情页
- [ ] 添加事件评论功能
- [ ] 实现事件过滤和排序
- [ ] 添加事件导出功能

**Day 4-5: 通知渠道**
- [ ] 实现 NotificationChannel 模型
- [ ] 实现 Email 通知器
- [ ] 实现 Slack Webhook 通知器
- [ ] 实现 Mattermost Webhook 通知器
- [ ] 实现飞书 Webhook 通知器
- [ ] 创建通知渠道配置页面

**Day 6-7: 告警分发**
- [ ] 实现 NotificationDispatchJob
- [ ] 添加告警延迟逻辑
- [ ] 实现告警去重
- [ ] 添加通知日志
- [ ] 实现通知测试功能

**Day 8-10: 心跳监控**
- [ ] 实现心跳接收端点
- [ ] 添加心跳 Token 生成
- [ ] 实现心跳超时检测
- [ ] 创建心跳监控配置
- [ ] 编写集成测试

#### 交付物
- 完整的事件管理系统
- 4 种通知渠道
- 告警分发系统
- 心跳监控功能

---

### 11.4 Phase 4: 高级功能 (Week 7-8)

#### 目标
- 实现剩余监控类型
- 实现维护窗口
- 添加响应时间统计
- 实现数据清理

#### 任务清单

**Day 1-3: 剩余监控类型**
- [ ] 实现 API 监控 (JSON 断言)
- [ ] 实现域名过期监控
- [ ] 添加响应时间监控
- [ ] 编写集成测试

**Day 4-5: 维护窗口**
- [ ] 实现 MaintenanceWindow 模型
- [ ] 创建维护窗口配置页面
- [ ] 实现维护窗口激活检测
- [ ] 添加重复维护窗口
- [ ] 集成到告警逻辑

**Day 6-7: 响应时间统计**
- [ ] 实现 ResponseTimeStat 模型
- [ ] 添加小时聚合任务
- [ ] 添加天聚合任务
- [ ] 实现响应时间图表
- [ ] 添加 p95 统计

**Day 8-10: 数据清理**
- [ ] 实现 DataCleanupJob
- [ ] 添加检查结果清理
- [ ] 添加通知日志清理
- [ ] 添加响应时间统计清理
- [ ] 配置清理调度

#### 交付物
- 完整的 10 种监控类型
- 维护窗口功能
- 响应时间统计系统
- 数据清理系统

---

### 11.5 Phase 5: 状态页面 (Week 9-10)

#### 目标
- 实现状态页面功能
- 添加品牌定制
- 实现事件公告
- 优化性能

#### 任务清单

**Day 1-3: 状态页面基础**
- [ ] 实现 StatusPage 模型
- [ ] 创建状态页面配置
- [ ] 实现监控器关联
- [ ] 添加分组显示
- [ ] 实现公开访问

**Day 4-5: 品牌定制**
- [ ] 添加 Logo 上传
- [ ] 实现主题颜色配置
- [ ] 添加布局选项
- [ ] 实现内容显示控制
- [ ] 添加密码保护

**Day 6-7: 事件公告**
- [ ] 实现 Announcement 模型
- [ ] 创建公告发布界面
- [ ] 实现公告更新
- [ ] 添加状态时间线
- [ ] 实现公告解决

**Day 8-10: 优化与测试**
- [ ] 添加页面缓存
- [ ] 优化查询性能
- [ ] 添加 SEO 设置
- [ ] 编写集成测试
- [ ] 性能测试

#### 交付物
- 完整的状态页面功能
- 品牌定制功能
- 事件公告系统
- 性能优化

---

### 11.6 Phase 6: 部署与优化 (Week 11-12)

#### 目标
- 完善 Docker 配置
- 部署到生产环境
- 监控和日志
- 文档完善

#### 任务清单

**Day 1-3: Docker 完善**
- [ ] 优化 Dockerfile
- [ ] 完善 docker-compose.yml
- [ ] 添加 Nginx 配置
- [ ] 配置 SSL 证书
- [ ] 添加健康检查

**Day 4-5: 生产部署**
- [ ] 配置 AWS 服务器
- [ ] 部署数据库
- [ ] 部署应用
- [ ] 配置域名
- [ ] 测试生产环境

**Day 6-7: 监控与日志**
- [ ] 添加应用日志
- [ ] 配置日志聚合
- [ ] 添加性能监控
- [ ] 配置告警
- [ ] 添加备份脚本

**Day 8-10: 文档与测试**
- [ ] 编写用户文档
- [ ] 编写 API 文档
- [ ] 编写部署文档
- [ ] 添加端到端测试
- [ ] 性能测试和优化

#### 交付物
- 生产就绪的 Docker 配置
- AWS 部署文档
- 监控和日志系统
- 完整的项目文档

---

## 附录

### A. 常用命令

```bash
# 开发环境
rails server                    # 启动开发服务器
rails console                   # Rails 控制台
rails db:migrate                # 运行迁移
rails db:seed                   # 加载种子数据
rails test                      # 运行测试
bundle exec good_job start      # 启动 Good Job worker

# Docker 环境
docker-compose up -d            # 启动所有服务
docker-compose down             # 停止所有服务
docker-compose logs -f app      # 查看应用日志
docker-compose exec app rails console  # Rails 控制台
docker-compose exec app rails db:migrate  # 运行迁移

# 生产环境
./deploy.sh                     # 部署脚本
./backup.sh                     # 备份脚本
./restore.sh <backup_file>      # 恢复脚本
```

### B. 故障排除

#### 数据库连接失败
```bash
# 检查数据库状态
docker-compose ps db

# 查看数据库日志
docker-compose logs db

# 重启数据库
docker-compose restart db
```

#### 应用启动失败
```bash
# 查看应用日志
docker-compose logs app

# 进入容器调试
docker-compose exec app bash

# 检查环境变量
docker-compose exec app env
```

#### 任务不执行
```bash
# 检查 Good Job 状态
docker-compose exec app rails good_job status

# 查看任务队列
docker-compose exec app rails good_job jobs

# 重启 worker
docker-compose restart worker
```

### C. 性能调优

#### 数据库优化
```ruby
# config/database.yml
production:
  adapter: postgresql
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 10 } %>
  timeout: 5000
  prepared_statements: true
  advisory_locks: true
```

#### 应用优化
```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  pool_size: ENV.fetch("RAILS_MAX_THREADS") { 10 },
  pool_timeout: 1
}
```

#### Good Job 优化
```ruby
# config/initializers/good_job.rb
GoodJob.configure do |config|
  config.max_threads = 10
  config.poll_interval = 30
  config.shutdown_timeout = 25
end
```

### D. 安全检查清单

- [ ] 更改默认管理员密码
- [ ] 配置强密码策略
- [ ] 启用 HTTPS
- [ ] 配置 CSP 头
- [ ] 限制 API 访问
- [ ] 配置防火墙
- [ ] 定期更新依赖
- [ ] 启用日志审计
- [ ] 配置备份策略
- [ ] 测试灾难恢复

---

*文档版本：1.0*
*最后更新：2026-06-23*
*维护者：Uptime Monitor Team*
