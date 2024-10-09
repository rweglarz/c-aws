data "aws_caller_identity" "account1" {
  provider = aws.my-account1
}

resource "cloudngfwaws_account" "account1" {
  account_id = data.aws_caller_identity.account1.account_id
}
