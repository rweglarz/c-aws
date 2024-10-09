data "aws_caller_identity" "account2" {
  provider = aws.my-account2
}

resource "cloudngfwaws_account" "account2" {
  account_id = data.aws_caller_identity.account2.account_id
}

resource "cloudngfwaws_account_onboarding_stack" "account2" {
  onboarding_cft = file("onboarding_cft_custom.yaml")
  # onboarding_cft = file("onboarding_cft_org.yaml")
  cft_role_name = aws_iam_role.account2.name
  external_id = cloudngfwaws_account.account2.external_id
  sns_topic_arn = cloudngfwaws_account.account2.sns_topic_arn
  trusted_account = cloudngfwaws_account.account2.trusted_account
  account_id = data.aws_caller_identity.account2.account_id
  endpoint_mode = "No"
  decryption_cert = "None"

  depends_on = [ 
    aws_iam_role_policy_attachment.account2
  ]
}
