# Architecture

```mermaid
flowchart LR
  Visitor --> CF[CloudFront + WAF]
  CF --> ALB[ALB static assets]
  ALB --> EC2[EC2 React release]
  CF --> API[REST API + regional WAF]
  API --> Lambda[Contact Lambda]
  Lambda --> Aurora[Aurora MySQL / Data API]
  Secrets[Secrets Manager managed DB secret] --> Aurora
  Lambda --> Outbox[SQS outbox]
  Outbox --> Relay[Worker Lambda]
  Relay --> Events[EventBridge]
  Events --> Queue[SQS + dead-letter queue]
  Queue --> Worker[Worker Lambda]
  Worker --> SNS[SNS request-ID notification]
  Worker --> Analytics[S3 anonymous metadata]
  Analytics --> Athena[Athena + Glue]
  Athena --> QuickSight[Daily enquiry dashboard]
  CloudTrail --> Audit[S3 audit logs]
  Audit --> Athena
  Admin[Administrator + Cognito] --> API
  Releases[S3 React releases] --> SSM[Systems Manager]
  SSM --> EC2
```

WAF protects CloudFront and direct API calls with managed rules and IP rate limits.
The ALB accepts the CloudFront origin-facing prefix list. EC2 accepts only its ALB.
No inbound SSH; EC2 uses IMDSv2, encrypted EBS and an instance role.
Static assets use HTTP from CloudFront to ALB; customer details use the HTTPS API.
Aurora uses isolated subnets, encrypted storage and no inbound SQL access.
Its existing RDS-managed Secrets Manager secret authenticates Data API access.

The API validates fields, binds SQL parameters and inserts a UUID-keyed contact row.
It then queues only non-personal metadata. A 202 means both operations succeeded.
Queue failure returns 503; the form retains the request ID for retry.
SQL and queueing are separate operations: see operations.md for reconciliation limits.
Notifications are at-least-once; duplicate SNS alerts can occur.
The service does not automatically phone customers; agents respond to notifications.
