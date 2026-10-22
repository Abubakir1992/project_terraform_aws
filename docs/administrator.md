# Administrator access

Public customers submit without login. There is no public login link.
Administrators visit /admin.html and authenticate through Cognito hosted sign-in.
OAuth uses authorization code, PKCE and state validation. Tokens stay in memory;
refresh requires sign-in again. Personal records are not stored in browser storage.

After apply, read the cognito_user_pool_id Terraform output.
Open that pool in AWS Cognito, create an invited user, and add the user to administrators.
Complete the emailed invitation and initial password flow. Self-registration is disabled.
No administrator password is generated or committed.
To manage membership in Terraform, set administrator_username in private tfvars
only after that user exists, then apply again.

API Gateway verifies token signature, issuer and expiry. Lambda additionally requires
the expected app-client ID, ID-token type, and exact administrators group membership
before reading any customer records. A forged browser claim cannot authorize a read.
Anonymous and non-admin callers cannot list or retrieve customer records.
The private table shows name, phone, email, interest and received time, 50 per page.
React renders fields as text. Load more retrieves the next page.
Authorized AWS account operators retain administrative access under your IAM policies.
