resource "cloudngfwaws_rulestack" "rs1" {
  name        = var.rule_stack
  scope       = "Local"
  account_id  = var.account_id //otherwise the account id will not be associated in webui
  description = "Made by Terraform"
  profile_config {
    anti_spyware = "BestPractice"
  }
}

resource "cloudngfwaws_security_rule" "any-allow" {
  rulestack   = cloudngfwaws_rulestack.rs1.name
  priority    = 5
  rule_list   = "LocalRule"
  name        = "any-allow"
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
  action   = "Allow"
  logging  = true
}

resource "cloudngfwaws_security_rule" "r1" {
  rulestack   = cloudngfwaws_rulestack.rs1.name
  priority    = 10
  rule_list   = "LocalRule"
  name        = "example-security-rule"
  description = "Configured via Terraform"
  source {
    cidrs = ["any"]
  }
  destination {
    cidrs = ["10.1.1.0/24"]
  }
  applications = ["web-browsing"]
  category {}
  action  = "Allow"
  logging = true
}

resource "cloudngfwaws_security_rule" "r3" {
  rulestack   = cloudngfwaws_rulestack.rs1.name
  priority    = 20
  rule_list   = "LocalRule"
  name        = "prot-port-test"
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
