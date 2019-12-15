terraform {
  required_version = "> 0.12.0"
}

provider "aws" {
  version = "2.42.0"
  region = "us-east-1"
}

variable "ACCESS_TOKEN" {}

data "archive_file" "function_source" {
  type = "zip"
  source_dir = "src"
  output_path = "toottime.zip"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_toottime_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "lambda" {
  filename         = data.archive_file.function_source.output_path
  function_name    = "toottime"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "bot.run"
  source_code_hash = "${filebase64sha256(data.archive_file.function_source.output_path)}"
  runtime          = "nodejs8.10"

  environment {
    variables = {
      TIMEZONE = "Australia/Melbourne"
      ACCESS_TOKEN = var.ACCESS_TOKEN
    }
  }
}

resource "aws_lambda_permission" "cloudwatch_trigger" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda.arn
}

resource "aws_cloudwatch_event_rule" "lambda" {
  name                = "toottime"
  description         = "Schedule trigger for lambda execution"
  schedule_expression = "rate(1 hour)"
}


resource "aws_cloudwatch_event_target" "lambda" {
  target_id = "toottime"
  rule      = aws_cloudwatch_event_rule.lambda.name
  arn       = aws_lambda_function.lambda.arn
}