output "lambda_cloudwatch_log_group" {
  description = "CloudWatch Logs group for the Lambda function."
  value       = aws_cloudwatch_log_group.lambda
}

output "this_lambda_function" {
  description = "Lambda function used for updating the DNS record."
  value       = aws_lambda_function.this
}
