#!/bin/bash
set -euo pipefail
dnf install -y httpd amazon-ssm-agent amazon-cloudwatch-agent awscli tar
systemctl enable --now amazon-ssm-agent
# Infrastructure health is independent of the later website release.
printf 'ready\n' > /var/www/html/health.txt
systemctl enable --now httpd
