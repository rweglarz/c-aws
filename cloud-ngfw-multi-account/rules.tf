resource "cloudngfwaws_rulestack" "this" {
  name        = "${var.name}-ma"
  scope       = "Local"
  account_id  = var.account_id //otherwise the account id will not be associated in webui
  description = "Made by Terraform"
  profile_config {
    #anti_spyware = "BestPractice"
    #anti_virus = "None"
    #anti_spyware = "None"
    vulnerability = "BestPractice"
    url_filtering                = "Custom"
    #url_filtering                = "None"
  }
}

resource "cloudngfwaws_security_rule" "rule1" {
  rulestack   = cloudngfwaws_rulestack.this.name
  priority    = 100
  rule_list   = "LocalRule"
  name        = "rule1"
  description = "Configured via Terraform"
  source {
    cidrs = ["any"]
  }
  destination {
    cidrs = ["any"]
  }
  category {}
  applications = ["web-browsing"]
  protocol     = "application-default"
  action       = "Allow"
  logging      = true
}

resource "cloudngfwaws_commit_rulestack" "this" {
  rulestack = cloudngfwaws_rulestack.this.name
  depends_on = [ 
    cloudngfwaws_security_rule.rule1
  ]
}
