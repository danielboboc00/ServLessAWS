# Create an IAM policy document that allows a Lambda function to assume a role
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Create an IAM role for the Lambda function to assume
resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

# Create a Lambda function named 'files' using the 'deployment.zip' file in the 'files' directory
resource "aws_lambda_function" "files" {
  filename      = "files/deployment.zip"
  function_name = "files"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "main"
  runtime       = "go1.x"

  # Set environment variables for the Lambda function
  environment {
    variables = {
      DB_REGION   = "us-east-2"
      DB_USERNAME = "lambda"
      DB_HOST     = "exercitiul-03302199317f7830.cgqpv2n3kmvi.us-east-2.rds.amazonaws.com"
      DB_PORT     = "3306"
      DB_NAME     = "DevOps"
    }
  }
}

# Create an API Gateway REST API
resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "APIGateway"
  description = "API Gateway for Files Lambda Function"
}

# Create a resource for the API Gateway
resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "{proxy+}"
}

# Create a method for the API Gateway resource
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

# Integrate the API Gateway with the Lambda function
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.files.invoke_arn
}

# Grant the API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.files.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
}
