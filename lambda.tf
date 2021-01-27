data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_lambda_function" "this" {
  function_name = var.name

  runtime                        = "nodejs12.x"
  handler                        = "index.handler"
  timeout                        = 5
  reserved_concurrent_executions = 3

  environment {
    variables = {
      CREDENTIALS = "${var.authentication.username}:${var.authentication.password}"
      ZONE_ID     = var.zone_id
      DOMAIN_NAME = var.domain_name
    }
  }

  role = aws_iam_role.this.arn

  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256

  tags = var.tags

  depends_on = [aws_cloudwatch_log_group.lambda]
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src"
  output_path = ".terraform/tmp/lambda/${var.name}.zip"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name = "lambda-${var.name}"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

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

resource "aws_iam_role_policy" "lambda_cloudwatch_log_group" {
  name   = "cloudwatch-log-group"
  role   = aws_iam_role.this.name
  policy = data.aws_iam_policy_document.lambda_cloudwatch_log_group.json
}

data "aws_iam_policy_document" "route53_zone_change_records" {
  statement {
    actions = ["route53:ChangeResourceRecordSets"]

    resources = ["arn:aws:route53:::hostedzone/${var.zone_id}"]
  }
}

resource "aws_iam_role_policy" "lambda_route53_zone_change_records" {
  name   = "route53-zone-change-records"
  role   = aws_iam_role.this.name
  policy = data.aws_iam_policy_document.route53_zone_change_records.json
}

resource "aws_lambda_permission" "this" {
  function_name = aws_lambda_function.this.arn
  action        = "lambda:InvokeFunction"

  principal  = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_stage.this.execution_arn}/GET${local.apigateway_path}"
}
