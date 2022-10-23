resource "cloudngfwaws_rulestack" "rs1" {
  name        = var.rule_stack
  scope       = "Local"
  account_id  = var.account_id //otherwise the account id will not be associated in webui
  description = "Made by Terraform"
  profile_config {
    #anti_spyware = "BestPractice"
    #anti_virus = "None"
    #anti_spyware = "None"
    #vulnerability = "None"
    outbound_trust_certificate = "panka-trust"
    outbound_untrust_certificate = "panka-untrust"
    #outbound_trust_certificate = "self-signed-trust2"
  }
}

resource "cloudngfwaws_security_rule" "r1" {
  rulestack   = cloudngfwaws_rulestack.rs1.name
  priority    = 100
  rule_list   = "LocalRule"
  name        = "example-security-rule-2"
  description = "Configured via Terraform"
  source {
    cidrs = ["any"]
  }
  destination {
    cidrs = ["10.1.1.0/24"]
  }
  category {}
  applications = ["web-browsing"]
  protocol     = "application-default"
  action  = "Allow"
  logging = true
}

resource "cloudngfwaws_security_rule" "r3" {
  rulestack   = cloudngfwaws_rulestack.rs1.name
  priority    = 200
  rule_list   = "LocalRule"
  name        = "prot-port-test-2"
  description = "only works with app any"
  source {
    cidrs = ["any"]
  }
  destination {
    cidrs = ["10.1.1.0/24"]
  }
  applications = ["any"]
  prot_port_list = [
    "UDP:660",
    "UDP:66",
    "TCP:80",
    "TCP:443",
    "TCP:8080",
  ]
  category {}
  action  = "Allow"
  logging = true
}

resource "cloudngfwaws_security_rule" "any-allow-decrypt-2" {
  rulestack   = cloudngfwaws_rulestack.rs1.name
  priority    = 300
  rule_list   = "LocalRule"
  name        = "any-allow-decrypt-2"
  description = "Configured via Terraform"
  source {
    cidrs = ["any"]
  }
  destination {
    cidrs = ["any"]
  }
  applications = ["any"]
  category {}
  protocol = "any"

  decryption_rule_type = "SSLOutboundInspection"
  action   = "Allow"
  logging  = true
}
