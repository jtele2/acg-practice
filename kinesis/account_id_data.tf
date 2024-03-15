# Use: ${data.aws_caller_identity.current.account_id} in place of account id

data "aws_caller_identity" "current" {}
