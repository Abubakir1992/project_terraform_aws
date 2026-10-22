# Administrator access

Public customers submit without login. There is no public login link.
Administrators visit /admin.html and authenticate through Cognito hosted sign-in.
OAuth uses authorization code, PKCE and state validation. Tokens stay in memory;
refresh requires sign-in again. Personal records are not stored in browser storage.

Set administrator_username to your administrator email in private tfvars.
Terraform creates that invited Cognito account and its administrators membership.
The local deployment uses your supplied email. Cognito sends the temporary-password
invitation; complete that flow yourself. No password is committed to Git.
For an existing user, import the Cognito user into Terraform before managing it.
Self-registration is disabled. A recreated pool needs a new user, not an old pool UUID.

API Gateway verifies token signature, issuer and expiry. Lambda additionally requires
the expected app-client ID, ID-token type, and exact administrators group membership
before reading any customer records. A forged browser claim cannot authorize a read.
Anonymous and non-admin callers cannot list or retrieve customer records.
The private table shows name, phone, email, interest and received time, 50 per page.
React renders fields as text. Load more retrieves the next page.
Authorized AWS account operators retain administrative access under your IAM policies.
