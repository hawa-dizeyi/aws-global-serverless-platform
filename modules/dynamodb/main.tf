locals {
  full_table_name = "${var.name_prefix}-${var.table_name}"
}

resource "aws_dynamodb_table" "this" {
  name         = local.full_table_name
  billing_mode = "PAY_PER_REQUEST"

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  hash_key  = var.hash_key
  range_key = var.range_key

  attribute {
    name = var.hash_key
    type = "S"
  }

  attribute {
    name = var.range_key
    type = "S"
  }

  ttl {
    attribute_name = var.ttl_attribute_name
    enabled        = true
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  replica {
    region_name = var.secondary_region
  }
}
