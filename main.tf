terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "random_string" "random" {
  length           = 16
  special          = true
  override_special = "/@£$"
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_cognito_user_pool" "pool" {
    name = "userpool-tech-challenge"
    account_recovery_setting {
        recovery_mechanism {
            name     = "verified_email"
            priority = 1
        }
    }
    password_policy {
        require_lowercase = false
        require_numbers = false
        require_symbols = false
        require_uppercase = false
        minimum_length = 6
    }
    schema {
        name                     = "email"
        attribute_data_type      = "String"
        mutable                  = true
        required                 = true
    }
    schema {
        name                     = "cpf"
        attribute_data_type      = "String"
        mutable                  = false
        required                 = false
        string_attribute_constraints {
            max_length = 11
            min_length = 11
        }
    }
    lifecycle {
        ignore_changes = [
            schema     ### AWS doesn't allow schema updates, so every build will re-create the user pool unless we ignore this bit
        ]
    }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "create-user-in-cognito-userpool/index.mjs"
  output_path = "1_index.js.zip"
    
}

resource "aws_lambda_function" "create-user-in-userpool-lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "1_index.js.zip"
  function_name = "create-user-in-cognito-userpool"
  role          = "arn:aws:iam::687277442149:role/LabRole"
  handler       = "index.handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "nodejs18.x"

  environment {
    variables = {
      USER_POOL_ID = aws_cognito_user_pool.pool.id
    }
  }
}

data "archive_file" "lambda2" {
  type        = "zip"
  source_file = "read-user-from-cognito-userpool/index.mjs"
  output_path = "2_index.js.zip"
    
}

resource "aws_lambda_function" "read_user_from_userpool_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "2_index.js.zip"
  function_name = "read-user-from-cognito-userpool"
  role          = "arn:aws:iam::687277442149:role/LabRole"
  handler       = "index.handler"

  source_code_hash = data.archive_file.lambda2.output_base64sha256

  runtime = "nodejs18.x"

  environment {
    variables = {
      USER_POOL_ID = aws_cognito_user_pool.pool.id
    }
  }
}
resource "aws_api_gateway_rest_api" "techchallenge-gateway-api" {
  name = "techchallenge-api-gateway"
}
resource "aws_lambda_permission" "apigw" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.read_user_from_userpool_lambda.arn}"
    principal     = "apigateway.amazonaws.com"
    source_arn = "${aws_api_gateway_rest_api.techchallenge-gateway-api.execution_arn}/*/*"
  }

  resource "aws_lambda_permission" "apigw2" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.create-user-in-userpool-lambda.arn}"
    principal     = "apigateway.amazonaws.com"
    source_arn = "${aws_api_gateway_rest_api.techchallenge-gateway-api.execution_arn}/*/*"
  }