data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Write permissions for CloudWatch Logs groups are granted via a service wide used IAM role
# https://eu-west-1.console.aws.amazon.com/apigateway/home?region=eu-west-1#/settings
resource "aws_cloudwatch_log_group" "apigateway" {
  name = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.this.id}/${local.apigateway_stage_name}"

  retention_in_days = 3

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "lambda" {
  name = "/aws/lambda/${var.name}"

  retention_in_days = 3

  tags = var.tags
}

data "aws_iam_policy_document" "lambda_cloudwatch_log_group" {
  statement {
    actions   = ["logs:DescribeLogStreams"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }
}
