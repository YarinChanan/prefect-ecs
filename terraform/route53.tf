#Requests and provisions an SSL/TLS certificate from AWS Certificate Manager (ACM).
resource "aws_acm_certificate" "prefect_cert" {
  domain_name               = "prefect.sandbox.insait-internal.com"
  validation_method         = "DNS"
  subject_alternative_names = ["prefect.sandbox.insait-internal.com"]


  lifecycle {
    create_before_destroy = true  #ensures that a new certificate is created before the old one is deleted
  }
}


# ACM requires DNS validation to prove domain ownership; Terraform automatically adds the necessary records.
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.prefect_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.sandbox_insait_internal_com.zone_id
}



#Designed to wait and confirm that the ACM certificate requested has been successfully validated
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.prefect_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}


#data source - used to retrieve information about an existing Route 53 hosted zone.
data "aws_route53_zone" "sandbox_insait_internal_com" {
  name = "sandbox.insait-internal.com."
}


#Resource creates an "A" alias record in Route 53, pointing the custom domain (prefect.sandbox.insait-internal.com) to (ALB).
resource "aws_route53_record" "prefect_record" {
  zone_id = data.aws_route53_zone.sandbox_insait_internal_com.zone_id
  name    = "prefect.sandbox.insait-internal.com"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

