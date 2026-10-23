# CloudTrail and Athena

CloudTrail writes multi-region management events to a private encrypted audit S3 bucket.
Log validation is enabled. This audits AWS control-plane activity, not browser visits.
Data events and website page-view tracking are not enabled.
Customer form bodies are not deliberately logged.

The separate analytics bucket stores one object per request ID containing only
request_id, event_date, interest and requests. No name, email or phone is exported.
Retries overwrite the same object, avoiding duplicate counts for that request ID.
Use the saved Athena query for daily aggregates by riding style.
Rows appear after a successful submission and queue processing.

Athena workgroup: Terraform output athena_workgroup.
Glue database: moto_analytics. Tables: contacts and cloudtrail.
Saved queries cover daily enquiries and AWS API activity/error counts.
Query results use a separate encrypted S3 bucket and expire after 30 days.
Each query has a 1 GiB scan cap; larger audit queries can hit that cap.

Analyze data in the Athena query editor using workgroup moto-analytics.
