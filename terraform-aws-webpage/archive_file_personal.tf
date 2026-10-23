data "archive_file" "personal" {
  type             = "zip"
  output_path      = "${path.module}/personal-api.zip"
  output_file_mode = "0755"
  dynamic "source" {
    for_each = toset(["handler.ps1", "contacts.ps1", "database.ps1", "validation.ps1"])
    content {
      content  = file("${path.module}/../personal-api/${source.value}")
      filename = source.value
    }
  }
  dynamic "source" {
    for_each = toset(["bootstrap", "runtime.ps1", "sdk.ps1"])
    content {
      content  = replace(file("${path.module}/../lambda-runtime/${source.value}"), "\r", "")
      filename = source.value
    }
  }
}
