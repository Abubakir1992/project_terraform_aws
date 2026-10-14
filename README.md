# Terraform AWS React and Aurora personal-data app

React on EC2 behind an HTTPS ALB saves personal details through API Gateway,
Cognito authentication, a Python Lambda, and Aurora MySQL Serverless v2 Data API.
The database runs in isolated subnets, with no public SQL access. AWS manages the
database password in Secrets Manager; Terraform and React never receive it.

The form collects full name and email, plus optional phone and address. Each
invited Cognito user owns one record in `personal_data.people`. Saving again
updates that user's record. There is no public listing or read endpoint.

## Deployment

1. In ACM **us-east-1**, request and validate a certificate for a domain you own,
   such as `app.example.com`. Keep the certificate's DNS validation records.
2. In `terraform-aws-webpage`, provide the existing AWS credential variables
   securely, plus these nonsecret settings in a local ignored `terraform.tfvars`:

   ```hcl
   website_domain      = "app.example.com"
   acm_certificate_arn = "arn:aws:acm:us-east-1:ACCOUNT:certificate/CERTIFICATE-ID"
   ```

3. Check engine availability in your account/region before applying:

   ```sh
   aws rds describe-db-engine-versions --engine aurora-mysql --region us-east-1 \
     --query 'DBEngineVersions[].EngineVersion'
   ```

   Default: `8.0.mysql_aurora.3.10.3`. Override `aurora_engine_version` if needed
   with an available Aurora MySQL 3.x version supporting Data API and Serverless v2.
4. Run `terraform init`, `terraform plan -out=personal-data.tfplan`, review the plan, and run
   `terraform apply personal-data.tfplan`. This creates billable AWS resources and rolls EC2
   instances to a new launch template. It does not modify `state-bootstrap`.
5. Point your domain to the `alb_dns_name` output with a DNS CNAME (or Route 53
   alias). Open the `website` output over HTTPS. HTTP redirects to this domain.
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

No resources are applied by opening or merging this PR. Configure DNS, ACM, and
invite users before using real personal data. Set an appropriate retention/deletion
process for records and their backups before production use.
