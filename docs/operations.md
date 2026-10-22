# Operations and AWS acceptance checks

1. Submit test details and verify the dialog and one Aurora contact_requests row.
2. No token and non-admin token: GET /api/people must return 401/403.
3. Administrator: sign in, read records, and exercise pagination.
4. Confirm SNS subscription and receive a request-ID-only notification.
5. Check queues drain and the dead-letter queue stays empty.
6. Run the Athena daily query, then open the QuickSight dashboard.
7. Verify CloudTrail delivery and its audit query after logs arrive.
8. Replace an instance and verify SSM installs the current React release.
9. Edit React only and redeploy without another infrastructure apply.

CloudWatch alarms monitor queue backlogs, dead letters and API 5xx responses.
Application logs omit personal fields and raw exception details.
WAF sampling and API body tracing are disabled to avoid capturing contact payloads.
SQS retries failed items individually, then moves repeated failures to the dead queue.
EventBridge retries delivery for 24 hours; inspect failed-invocation metrics.
SNS notifications can repeat because delivery is at-least-once.

The SQL insert and outbox enqueue are not atomic. If queueing fails after the save,
a client retry with the same request ID queues it without inserting another customer.
If the client abandons the retry, administrators can still see the saved enquiry,
but its notification and analytics row can be missing. Reconcile saved requests
against analytics if notifications are operationally critical.
This demo is not a transactional database outbox with guaranteed atomic delivery.

Assets publish before HTML. SSM installs entry pages after their dependencies.
Old hashed assets remain for open browser tabs; release cleanup is manual.
EventBridge Scheduler triggers association reconciliation every five minutes.
Check association execution details when a deployment fails.
The ALB health check uses /health.txt independently of the React release.

Define customer retention/deletion policy before production use.
Aurora backups retain seven days; individual customer deletion is currently manual.
Analytics and audit logs persist until removed or the development stack is destroyed.
Production should enable database deletion protection, final snapshots and protected logs.
