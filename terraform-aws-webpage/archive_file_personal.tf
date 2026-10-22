data "archive_file" "personal" {
  type        = "zip"
  output_path = "${path.module}/personal-api.zip"
  dynamic "source" {
    for_each = toset(["handler.py", "contacts.py", "database.py", "validation.py"])
    content {
      content  = file("${path.module}/../personal-api/${source.value}")
      filename = source.value
    }
  }
}
