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
  output_path = "index.js.zip"
    
}

resource "aws_lambda_function" "test_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "index.js.zip"
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