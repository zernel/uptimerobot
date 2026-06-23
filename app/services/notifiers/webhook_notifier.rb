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
              content: incident.ongoing? ? 'Monitor Down' : 'Monitor Up'
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
