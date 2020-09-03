provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

provider "aws" {
  version = "~> 3.0"
  region  = "ap-southeast-2"

  assume_role {
    role_arn = var.dns_role_arn
  }
}

resource "aws_route53_record" "adfs-sandpit" {
  zone_id = var.dns_zone_id
  name    = local.sts_fqdn
  type    = "A"
  ttl     = 60
  records = [azurerm_public_ip.adfs-sandpit.ip_address]
}


resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = var.acme_account_email
}

resource "acme_certificate" "sandpit" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = local.sts_fqdn
  #subject_alternative_names = [local.sts_fqdn]

  dns_challenge {
    provider = "route53"
    
    config = {
      AWS_HOSTED_ZONE_ID = var.dns_zone_id
    }
  }
}