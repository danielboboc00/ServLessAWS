data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_policy" "lambda_execution_policy" {
  name = "lambda_execution_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds-data:ExecuteStatement",
          "rds-data:BatchExecuteStatement",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["rds-db:connect"]
        Resource = ["arn:aws:rds-db:us-east-2:193118517679:dbuser:*/lambda"]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the IAM policy to the IAM role for the Lambda function
resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}

resource "aws_lambda_function" "files" {
  filename      = "files/deployment.zip"
  function_name = "handler"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "files"
  runtime       = "go1.x"
  timeout       = 5

  vpc_config {
    subnet_ids         = [aws_subnet.exercitiu_subnet_public.id] // changed to public subnet
    security_group_ids = [aws_security_group.sg_exercitiu.id]
  }

  environment {
    variables = {
      DB_REGION   = "us-east-2"
      DB_USERNAME = "lambda"
      DB_HOST     = "exercitiul-b817194fce0f0c50.cgqpv2n3kmvi.us-east-2.rds.amazonaws.com"
      DB_PORT     = "3306"
      DB_NAME     = "DevOps"
    }
  }
}

resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "APIGateway"
  description = "API Gateway for Files Lambda Function"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.files.invoke_arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.files.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
}
