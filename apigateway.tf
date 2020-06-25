locals {
  apigateway_stage_name = "production"
  apigateway_path       = "/update"
}

resource "aws_api_gateway_rest_api" "this" {
  name = var.name

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  binary_media_types = ["*/*"]

  body = jsonencode({
    swagger = "2.0"

    info = {
      title   = var.name
      version = 1
    }

    schemes = ["https"]

    paths = {
      "${local.apigateway_path}" = {
        get = {
          responses = {}

          x-amazon-apigateway-integration = {
            uri        = aws_lambda_function.this.invoke_arn
            httpMethod = "POST"
            type       = "aws_proxy"
          }
        }
      }
    }

    x-amazon-apigateway-binary-media-types = ["*/*"]
  })


  tags = var.tags
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = "import_${md5(aws_api_gateway_rest_api.this.body)}"

  lifecycle {
    # The stage needs to use the new deployment first before dropping the old deployment
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = local.apigateway_stage_name

  deployment_id = aws_api_gateway_deployment.this.id

  tags = var.tags

  depends_on = [aws_cloudwatch_log_group.apigateway]
}

resource "aws_api_gateway_method_settings" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    data_trace_enabled = true
    logging_level      = "INFO"
    metrics_enabled    = true
  }
}
