#!/bin/bash
set -euo pipefail

yum update -y
yum install -y amazon-cloudwatch-agent jq aws-cli

# Fetch DB credentials from Secrets Manager
SECRET=$(aws secretsmanager get-secret-value \
  --region "${aws_region}" \
  --secret-id "${db_secret_arn}" \
  --query SecretString \
  --output text)

DB_PASSWORD=$(echo "$SECRET" | jq -r '.password')

# Export environment variables for the application
cat > /etc/app.env <<EOF
DB_HOST=${db_endpoint}
DB_NAME=${db_name}
DB_USER=$(echo "$SECRET" | jq -r '.username')
DB_PASS=$DB_PASSWORD
APP_PORT=8080
EOF

# Example: install and run a simple Node.js / Python app here
# For demo purposes, we use a basic Python HTTP server with a health endpoint
yum install -y python3

cat > /opt/app.py <<'PYEOF'
from http.server import HTTPServer, BaseHTTPRequestHandler
import json, os

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok", "tier": "app"}).encode())
        else:
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"message": "Hello from App Tier"}).encode())

    def log_message(self, format, *args):
        pass  # suppress default logging; use CloudWatch

HTTPServer(('0.0.0.0', 8080), Handler).serve_forever()
PYEOF

cat > /etc/systemd/system/app.service <<'EOF'
[Unit]
Description=Application Tier Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/app.py
EnvironmentFile=/etc/app.env
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable app
systemctl start app

# CloudWatch agent config
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'EOF'
{
  "agent": { "metrics_collection_interval": 60 },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          { "file_path": "/var/log/messages", "log_group_name": "/ec2/app/messages" }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "CWAgent/AppTier",
    "metrics_collected": {
      "cpu":  { "measurement": ["cpu_usage_idle","cpu_usage_user","cpu_usage_system"] },
      "mem":  { "measurement": ["mem_used_percent"] },
      "disk": { "measurement": ["disk_used_percent"], "resources": ["/"] }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
