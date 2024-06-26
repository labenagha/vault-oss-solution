resource "aws_iam_policy" "terraform_state_management_policy" {
  name        = var.state_bucket_policy_name
  description = "Policy for Terraform state management in S3 and DynamoDB"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = ["*"]
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ],
        Resource = "arn:aws:dynamodb:us-east-1:${data.aws_caller_identity.current.account_id}:table/terraform-lock-table"
      }
    ]
  })
}
