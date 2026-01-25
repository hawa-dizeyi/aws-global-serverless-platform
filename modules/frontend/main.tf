locals {
  bucket_name = "${var.name_prefix}-site"
}

resource "aws_s3_bucket" "site" {
  count  = var.enable ? 1 : 0
  bucket = local.bucket_name
}

resource "aws_s3_bucket_public_access_block" "site" {
  count                   = var.enable ? 1 : 0
  bucket                  = aws_s3_bucket.site[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "site" {
  count  = var.enable ? 1 : 0
  bucket = aws_s3_bucket.site[0].id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  count  = var.enable ? 1 : 0
  bucket = aws_s3_bucket.site[0].id

  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

# Upload static files
resource "aws_s3_object" "assets" {
  for_each = var.enable ? fileset(var.site_dir, "**/*") : toset([])

  bucket       = aws_s3_bucket.site[0].id
  key          = each.value
  source       = "${var.site_dir}/${each.value}"
  etag         = filemd5("${var.site_dir}/${each.value}")
  content_type = each.value == "index.html" ? "text/html" : null
}

# ACM cert for CloudFront MUST be in us-east-1, so this module expects provider aws.use1.
resource "aws_acm_certificate" "site" {
  count             = var.enable ? 1 : 0
  domain_name       = var.root_domain
  validation_method = "DNS"

  subject_alternative_names = ["www.${var.root_domain}"]

  lifecycle { create_before_destroy = true }
}

resource "aws_route53_record" "cert_validation" {
  for_each = var.enable ? {
    for dvo in aws_acm_certificate.site[0].domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "site" {
  count                   = var.enable ? 1 : 0
  certificate_arn         = aws_acm_certificate.site[0].arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

resource "aws_cloudfront_origin_access_control" "oac" {
  count                             = var.enable ? 1 : 0
  name                              = "${var.name_prefix}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "site" {
  count = var.enable ? 1 : 0

  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  aliases = [var.root_domain, "www.${var.root_domain}"]

  origin {
    domain_name              = aws_s3_bucket.site[0].bucket_regional_domain_name
    origin_id                = "s3-site"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac[0].id
  }

  default_cache_behavior {
    target_origin_id       = "s3-site"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site[0].certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  depends_on = [aws_acm_certificate_validation.site]
}

# Allow CloudFront to read S3 bucket
data "aws_iam_policy_document" "bucket_policy" {
  count = local.enabled ? 1 : 0

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site[0].arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site[0].arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.site[0].id
  policy = data.aws_iam_policy_document.bucket_policy[0].json
}

# Route53 aliases
resource "aws_route53_record" "root_a" {
  count   = var.enable ? 1 : 0
  zone_id = var.zone_id
  name    = var.root_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site[0].domain_name
    zone_id                = aws_cloudfront_distribution.site[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_a" {
  count   = var.enable ? 1 : 0
  zone_id = var.zone_id
  name    = "www.${var.root_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site[0].domain_name
    zone_id                = aws_cloudfront_distribution.site[0].hosted_zone_id
    evaluate_target_health = false
  }
}

locals {
  enabled = var.enabled
}
