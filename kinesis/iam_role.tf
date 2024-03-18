# This was generated by terraformer and I edited it to make it more generic. The name for all of my resources is acgpractice733.

resource "aws_iam_role" "KinesisFirehoseServiceRole-PUT-S3-acgpractice733" {
  assume_role_policy = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      }
    }
  ],
  "Version": "2012-10-17"
}
POLICY

  managed_policy_arns   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/service-role/KinesisFirehoseServicePolicy-PUT-S3-acgpractice733"]
  max_session_duration  = "3600"
  name                  = "KinesisFirehoseServiceRole-PUT-S3-acgpractice733"
  path                  = "/service-role/"
  force_detach_policies = true
}
