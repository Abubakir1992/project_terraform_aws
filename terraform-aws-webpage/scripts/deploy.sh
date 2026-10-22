#!/bin/bash
set -euo pipefail
# No release exists immediately after infrastructure apply; retry next schedule.
aws s3api head-object --bucket '${bucket}' --key site/index.html >/dev/null 2>&1 || exit 0
exec 9>/run/moto-deploy.lock
flock -n 9 || exit 0
staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT
aws s3 sync 's3://${bucket}/site/' "$staging" --only-show-errors
test -s "$staging/index.html"
test -s "$staging/app-config.json"
cp -r "$staging/assets" "$staging/images" /var/www/html/
cp "$staging/credits.html" /var/www/html/
cp "$staging/app-config.json" /var/www/html/
cp "$staging/admin.html" /var/www/html/
cp "$staging/index.html" /var/www/html/
restorecon -R /var/www/html
curl -fsS http://localhost/ >/dev/null
