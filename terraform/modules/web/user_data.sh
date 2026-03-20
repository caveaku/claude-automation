#!/bin/bash
set -euo pipefail

# Install nginx and configure as reverse proxy to app tier
yum update -y
yum install -y nginx amazon-cloudwatch-agent

# Configure nginx
cat > /etc/nginx/conf.d/app.conf <<'EOF'
server {
    listen 80;
    server_name _;

    location /health {
        return 200 "OK";
        add_header Content-Type text/plain;
    }

    location / {
        proxy_pass         http://${app_alb_dns}:80;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30;
        proxy_send_timeout    30;
        proxy_read_timeout    30;
    }
}
EOF

systemctl enable nginx
systemctl start nginx

# CloudWatch agent config
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'EOF'
{
  "agent": { "metrics_collection_interval": 60 },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          { "file_path": "/var/log/nginx/access.log", "log_group_name": "/ec2/web/nginx/access" },
          { "file_path": "/var/log/nginx/error.log",  "log_group_name": "/ec2/web/nginx/error"  }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "CWAgent/WebTier",
    "metrics_collected": {
      "cpu":    { "measurement": ["cpu_usage_idle","cpu_usage_user","cpu_usage_system"] },
      "mem":    { "measurement": ["mem_used_percent"] },
      "disk":   { "measurement": ["disk_used_percent"], "resources": ["/"] }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
