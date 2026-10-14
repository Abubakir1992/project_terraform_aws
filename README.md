# Terraform AWS React and Aurora personal-data app

React on EC2 behind CloudFront HTTPS and an ALB saves personal details through API Gateway,
Cognito authentication, a Python Lambda, and Aurora MySQL Serverless v2 Data API.
The database runs in isolated subnets, with no public SQL access. AWS manages the
database password in Secrets Manager; Terraform and React never receive it.

The form collects full name and email, plus optional phone and address. Each
invited Cognito user owns one record in `personal_data.people`. Saving again
updates that user's record. There is no public listing or read endpoint.

## Deployment

1. Pull the `feat/aurora-personal-data` branch. No purchased domain, DNS setup,
   or ACM certificate is required. CloudFront supplies an AWS HTTPS address.
2. In `terraform-aws-webpage`, remove old `website_domain` and
   `acm_certificate_arn` entries from all local `.tfvars`/`.auto.tfvars` files and
   any command-line `-var` arguments. Keep the existing AWS credential settings
   secure and keep your existing Terraform backend and state.
3. Check engine availability in your account/region before applying:

   ```sh
   aws rds describe-db-engine-versions --engine aurora-mysql --region us-east-1 \
     --query 'DBEngineVersions[].EngineVersion'
   ```

   Default: `8.0.mysql_aurora.3.10.3`. Override `aurora_engine_version` if needed
   with an available Aurora MySQL 3.x version supporting Data API and Serverless v2.
4. Run `terraform init`, `terraform plan -out=personal-data.tfplan`, review the
   plan, and run `terraform apply personal-data.tfplan`. Generate a new plan after
   changing variables or pulling changes. This creates billable AWS resources,
   creates a CloudFront distribution, changes the ALB HTTP listener to forward
   static content, and rolls EC2 instances. It does not modify `state-bootstrap`.
   If an old HTTPS listener exists in state, the plan removes it because CloudFront
   now provides HTTPS. Resources from an earlier partial apply stay in your state;
   there is no need to destroy everything or start a new state.
5. Run `terraform output -raw website` and open that exact `https://...cloudfront.net`
   address. CloudFront deployment and the EC2 rolling refresh can take several
   minutes. Cognito callbacks, logout URLs, API CORS, and EC2's public app config
   all use the generated CloudFront hostname automatically.
6. In Cognito, open the pool identified by `cognito_user_pool_id`. Create an
   invited user with their email and send the invitation. The hosted sign-in page
   handles the temporary password and initial password change. Self-signup is
   disabled. Cognito uses its default invitation email delivery initially.
7. Sign in, save details, and verify the record in the Aurora query editor:

   ```sql
   SELECT owner_sub, full_name, email, phone, address, updated_at FROM people;
   ```

The table is created on the first authenticated save. The Lambda uses bound SQL
parameters and derives record ownership from the verified token, never the body.
Tokens stay in browser memory and expire after 15 minutes; sign in again after
expiry or reload. OAuth uses authorization code, PKCE, and state validation.

## Temporary HTTPS address

CloudFront uses its default `*.cloudfront.net` certificate and redirects viewer
HTTP requests to HTTPS. Its origin is the existing ALB over HTTP and serves only
static React assets and public app configuration. Personal data and bearer tokens
are sent directly from the browser to the HTTPS API Gateway endpoint; they never
travel through the HTTP ALB origin. Cognito sign-in is also HTTPS. CloudFront
caching is disabled, so config changes and frontend deployments need no cache
invalidation. OAuth callback query strings and cookies are not forwarded to EC2.
The address remains usable while this CloudFront distribution exists.

## Existing GitHub deployment

Apply Terraform before deploying the updated React form with the existing
`Deploy React to EC2` workflow. It checks that Terraform-generated
`/var/www/html/app-config.json` exists before replacing the frontend, and preserves
that config and `instance.json`. Config contains only public auth/API identifiers.
EC2 startup builds the same `react-app/src/main.jsx` as GitHub Actions, so scaling
does not bring back the old example UI. Update `EC2_HOSTS` and known hosts after
the ASG rolls instances, as required by the existing SSH deployment workflow.

## Validation and operations

```sh
cd react-app
npm ci
npm run build
cd ..
python -m unittest discover -s personal-api -v
cd terraform-aws-webpage
terraform fmt -check
terraform init -backend=false
terraform validate
```

PR checks run these validations without applying infrastructure. An AWS plan,
real Cognito login, and database write must be verified in your AWS account.

Aurora starts at 0.5 ACU and scales up to 2 ACU, with one writer and seven days of
backups. Storage and backups are encrypted. Deletion protection and a final
snapshot are enabled; to remove the database, explicitly disable protection and
choose a unique final snapshot name if `webpage-personal-final` already exists.
Lambda logging records request IDs on failures, without personal fields or tokens.
The Lambda role can execute statements only on this cluster and retrieve only its
managed secret. That secret belongs to the database administrator; future APIs
with broader query capabilities should use a separate restricted database user.

No resources are applied by opening or merging this PR. Invite users before using real personal data. Set an appropriate retention/deletion
process for records and their backups before production use.
