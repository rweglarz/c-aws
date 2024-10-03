data "aws_networkmanager_core_network_policy_document" "this" {
  core_network_configuration {
    vpn_ecmp_support = true
    asn_ranges       = ["64515-64520"]

    edge_locations {
      location = "eu-central-1"
      asn      = 64515
    }
    edge_locations {
      location = "eu-west-1"
      asn      = 64516
    }
    edge_locations {
      location = "us-east-1"
      asn      = 64517
    }
  }

  segments {
    name                          = "prod"
    require_attachment_acceptance = false
  }
  segments {
    name                          = "dev"
    require_attachment_acceptance = false
  }
  segments {
    name                          = "other"
    require_attachment_acceptance = false
  }

  attachment_policies {
    rule_number     = 100
    condition_logic = "or"
    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "env"
      value    = "prod"
    }
    action {
      association_method = "constant"
      segment            = "prod"
    }
  }

  attachment_policies {
    rule_number     = 110
    condition_logic = "or"
    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "env"
      value    = "dev"
    }
    action {
      association_method = "constant"
      segment            = "dev"
    }
  }
  
  attachment_policies {
    rule_number     = 900
    condition_logic = "or"
    conditions {
      type     = "any"
    }
    action {
      association_method = "constant"
      segment            = "other"
    }
  }
}