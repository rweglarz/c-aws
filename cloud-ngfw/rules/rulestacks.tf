resource "cloudngfwaws_rulestack" "rs1" {
  name        = var.rule_stack
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
    outbound_trust_certificate   = local.sm-trust
    outbound_untrust_certificate = local.sm-untrust
  }
}

resource "cloudngfwaws_custom_url_category" "rs1_cuc1" {
  rulestack   = cloudngfwaws_rulestack.rs1.name
  name        = "tf-custom-category"
  description = "Also configured by Terraform"
  url_list = [
    "demo.com",
    "github.com",
    "www.github.com",
    "github.githubassets.com",
  ]
  action = "alert"
}

resource "cloudngfwaws_custom_url_category" "rs1_block1" {
  rulestack   = cloudngfwaws_rulestack.rs1.name
  name        = "tf-custom-category-block"
  description = "Also configured by Terraform"
  url_list = [
    "www.oracle.com/in/java/technologies/downloads/",
  ]
  action = "alert"
}


resource "cloudngfwaws_predefined_url_category_override" "rs1_block" {
  for_each = toset([
    "auctions",
    "high-risk",
    "real-time-detection",
    "shareware-and-freeware",
  ])
  rulestack = cloudngfwaws_rulestack.rs1.name
  name      = each.key
  action    = "block"
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
    cidrs = [
      "10.1.1.0/24",
      "10.1.2.0/24"
    ]
  }
  category {}
  applications = ["web-browsing"]
  protocol     = "application-default"
  action       = "Allow"
  logging      = true
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

resource "cloudngfwaws_security_rule" "client-allow-no-decrypt" {
  rulestack   = cloudngfwaws_rulestack.rs1.name
  priority    = 271
  rule_list   = "LocalRule"
  name        = "client-allow-no-decrypt"
  description = "Configured via Terraform"
  source {
    cidrs = ["172.16.1.0/24"]
  }
  destination {
    cidrs = ["any"]
  }
  applications = ["any"]
  category {
    url_category_names = [
      "financial-services",
    ]
  }
  protocol = "any"

  #decryption_rule_type = "SSLOutboundInspection"
  action  = "Allow"
  logging = true
}

resource "cloudngfwaws_security_rule" "client-allow-decrypt" {
  rulestack   = cloudngfwaws_rulestack.rs1.name
  priority    = 272
  rule_list   = "LocalRule"
  name        = "client-allow-decrypt"
  description = "Configured via Terraform"
  source {
    cidrs = ["172.16.1.0/24"]
  }
  destination {
    cidrs = ["any"]
  }
  applications = ["any"]
  category {}
  protocol = "any"

  #decryption_rule_type = "SSLOutboundInspection"
  action               = "Allow"
  logging              = true
}

# resource "cloudngfwaws_security_rule" "block-custom" {
#   rulestack   = cloudngfwaws_rulestack.rs1.name
#   priority    = 299
#   rule_list   = "LocalRule"
#   name        = "block-a-few"
#   description = "Configured via Terraform"
#   source {
#     cidrs = ["any"]
#   }
#   destination {
#     cidrs = ["any"]
#   }
#   applications = ["any"]
#   category {
#     url_category_names = [
#       cloudngfwaws_custom_url_category.rs1_block1.name
#     ]
#   }
#   protocol = "any"

#   decryption_rule_type = "SSLOutboundInspection"
#   action               = "DenyResetBoth"
#   logging              = true
# }

resource "cloudngfwaws_security_rule" "any-allow-decrypt" {
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
  action               = "Allow"
  logging              = true
}
