locals {
  powershell_layer_path = "${path.module}/../build/lambda/runtime.zip"
}
resource "aws_s3_object" "powershell_runtime" {
  bucket                 = aws_s3_bucket.releases.id
  key                    = "runtime/powershell-${filebase64sha256(local.powershell_layer_path)}.zip"
  source                 = local.powershell_layer_path
  source_hash            = filebase64sha256(local.powershell_layer_path)
  server_side_encryption = "AES256"
}
resource "aws_lambda_layer_version" "powershell" {
  layer_name               = "moto-powershell"
  description              = "PowerShell 7.4.21 and AWS SDK for .NET 4, Linux x64"
  s3_bucket                = aws_s3_object.powershell_runtime.bucket
  s3_key                   = aws_s3_object.powershell_runtime.key
  source_code_hash         = filebase64sha256(local.powershell_layer_path)
  compatible_runtimes      = ["provided.al2023"]
  compatible_architectures = ["x86_64"]
}
