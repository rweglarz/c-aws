resource "cloudngfwaws_certificate" "s-trust" {
  rulestack   = cloudngfwaws_rulestack.rs1.name
  name        = "self-signed-trust2"
  self_signed = true
}
resource "cloudngfwaws_certificate" "s-untrust" {
  rulestack   = cloudngfwaws_rulestack.rs1.name
  name        = "self-signed-untrust2"
  self_signed = true
}

resource "cloudngfwaws_certificate" "sm-trust" {
  rulestack   = cloudngfwaws_rulestack.rs1.name
  name        = "panka-trust"
  //self_signed = false
  signer_arn = aws_secretsmanager_secret.trust.arn
}
resource "cloudngfwaws_certificate" "sm-untrust" {
  rulestack   = cloudngfwaws_rulestack.rs1.name
  name        = "panka-untrust"
  //self_signed = false
  signer_arn = aws_secretsmanager_secret.untrust.arn
}
/*
resource "cloudngfwaws_certificate" "test1" {
  rulestack   = cloudngfwaws_rulestack.rs1.name
  name        = "test1"
  self_signed = true
  signer_arn = aws_secretsmanager_secret.untrust.arn
}
*/



resource "aws_secretsmanager_secret" "trust" {
  name = "ngfw-trust"
  tags = {
    PaloAltoCloudNGFW = true,
  }
}
resource "aws_secretsmanager_secret_version" "trust" {
  secret_id     = aws_secretsmanager_secret.trust.id
  secret_string = jsonencode({
    private-key = file("${var.cert_path}/cert_decrypt-trusted-ca.key"),
    public-key = file("${var.cert_path}/cert_decrypt-trusted-ca.pem"),
  })
}

resource "aws_secretsmanager_secret" "untrust" {
  name = "ngfw-untrust"
  tags = {
    PaloAltoCloudNGFW = true,
  }
}
resource "aws_secretsmanager_secret_version" "untrust" {
  secret_id     = aws_secretsmanager_secret.untrust.id
  secret_string = jsonencode({
    private-key = file("${var.cert_path}/cert_decrypt-untrusted-ca.key"),
    public-key = file("${var.cert_path}/cert_decrypt-untrusted-ca.pem"),
  })
}
