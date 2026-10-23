# Destroy the development stack

The main configuration supports destroy without manual database switches.
Aurora deletion protection is false and final snapshots are skipped.
Application, audit, analytics and results buckets use force_destroy = true.
Destroy permanently removes customer records, logs and those bucket objects.
Export or back up anything you want to retain first.

```powershell
cd C:\Users\abubakir\Project_terraform\terraform-aws-webpage
terraform plan -destroy -out=destroy.tfplan
# Review Aurora deletion and bucket contents.
terraform apply destroy.tfplan
```

CloudFront disabling and database removal can take several minutes.
The separately bootstrapped Terraform state bucket is retained and protected.
The registered domain and pre-existing hosted zone are not deleted.
Terraform-managed website and certificate-validation DNS records are removed.

Apply and React deployment update the site; use destroy only for an intentional teardown.
