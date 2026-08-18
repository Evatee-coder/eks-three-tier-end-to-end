resource "aws_acm_certificate" "eks" {
  domain_name       = "eks.eva-tee.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Terraform = "true"
    repo      = "eks-terraform-two-tier-app"
  }
}

data "aws_route53_zone" "eva_tee" {
  name = "eva-tee.com"
}

resource "aws_route53_record" "eks_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.eks.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = data.aws_route53_zone.eva_tee.zone_id
}

resource "aws_acm_certificate_validation" "eks" {
  certificate_arn         = aws_acm_certificate.eks.arn
  validation_record_fqdns = [for record in aws_route53_record.eks_cert_validation : record.fqdn]
}

output "eks_certificate_arn" {
  value = aws_acm_certificate_validation.eks.certificate_arn
}