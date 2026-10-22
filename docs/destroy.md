# Destroy the development stack

The main configuration supports destroy without manual database switches.
Aurora deletion protection is false and final snapshots are skipped.
Application, audit, analytics and results buckets use force_destroy = true.
Destroy permanently removes customer records, logs and those bucket objects.
Export or back up anything you want to retain first.

```powershell
cd C:\Users\abubakir\Project_terraform\terraform-aws-webpage
terraform plan -destroy -out=destroy.tfplan
# Review Aurora, bucket contents and the QuickSight subscription deletion.
terraform apply destroy.tfplan
```

CloudFront disabling and database removal can take several minutes.
The separately bootstrapped Terraform state bucket is retained and protected.
The registered domain and pre-existing hosted zone are not deleted.
Terraform-managed website and certificate-validation DNS records are removed.

If Terraform creates QuickSight subscription, it manages subscription deletion too.
That subscription is account-wide: do not add unrelated projects then casually destroy it.
With create_quicksight_subscription = false, an existing subscription is left in place.
Account termination protection, if enabled later, must be disabled before deletion.
No AWS apply, deployment or destroy has been run during this source-code update.
