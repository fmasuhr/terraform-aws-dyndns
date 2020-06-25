provider "aws" {
  region = "eu-west-1"
}

resource "random_id" "password" {
  byte_length = 16
}

resource "aws_route53_zone" "this" {
  name = "example.com"
}

module "this" {
  source = "../.."

  name = "dyndns"

  zone_id     = aws_route53_zone.this.zone_id
  domain_name = "dyndns.${aws_route53_zone.this.name}"

  authentication = {
    username = "jdoe"
    password = random_id.password.hex
  }
}
