terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.41.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

# IAM policy granting access to the Firehose stream
resource "aws_iam_policy" "lambda_firehose_policy" {
  name        = "LambdaFirehosePutRecordPolicy"
  description = "IAM policy for allowing Lambda to put records to Firehose"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "firehose:PutRecord"
        Resource = aws_kinesis_firehose_delivery_stream.PUT-S3-acgpractice733.arn
        Effect   = "Allow"
      },
      {
        Action   = "kinesis:*"
        Resource = "*" # Laziness...
        Effect   = "Allow"
      },
      {
        Action   = "logs:*"
        Resource = "*"
        Effect   = "Allow",
      }
    ]
  })
}

# IAM role for the Lambda function
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "lambda_firehose_policy_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_firehose_policy.arn
}
