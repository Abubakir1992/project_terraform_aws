# CloudTrail, Athena and QuickSight

CloudTrail writes multi-region management events to a private encrypted audit S3 bucket.
Log validation is enabled. This audits AWS control-plane activity, not browser visits.
Data events and website page-view tracking are not enabled.
Customer form bodies are not deliberately logged.

The separate analytics bucket stores one object per request ID containing only
request_id, event_date, interest and requests. No name, email or phone is exported.
Retries overwrite the same object, avoiding duplicate counts for that request ID.
Daily aggregates by riding style feed the QuickSight dataset.
Rows appear after a successful submission and queue processing.

Athena workgroup: Terraform output athena_workgroup.
Glue database: moto_analytics. Tables: contacts and cloudtrail.
Saved queries cover daily enquiries and AWS API activity/error counts.
Query results use a separate encrypted S3 bucket and expire after 30 days.
Each query has a 1 GiB scan cap; larger audit queries can hit that cap.

QuickSight uses your current AWS account in us-east-1.
Terraform creates its subscription, native administrator, Athena data source,
DIRECT_QUERY dataset, and published daily-enquiry table dashboard.

```sh
terraform output -raw quicksight_invitation
terraform output -raw quicksight_dashboard
```

Complete the private administrator invitation before opening the dashboard.
The data-source role reads only anonymous analytics and query results;
it cannot read Aurora, Secrets Manager or CloudTrail objects.
The deployment identity needs IAM PassRole for that data-source role.
DIRECT_QUERY queries Athena when the dashboard loads; no SPICE refresh is needed.
This is an enquiry report, not a website traffic report.
QuickSight, Athena scans, WAF, Aurora, ALB and EC2 incur charges.
Live query execution and QuickSight rendering must be verified after AWS deployment.

Dashboard ownership belongs to the invited motohaus-admin user. AWS-console users
are separate QuickSight identities; administrator status alone does not share a dashboard.
Set quicksight_dashboard_viewer_arns in private tfvars to existing QuickSight user ARNs
for view/query access. The local deployment includes the active console administrator.
Open the us-east-1 region; an empty report means there are no retained enquiry rows.
