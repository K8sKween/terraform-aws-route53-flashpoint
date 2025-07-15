###Create Record Lambda

data "archive_file" "create_record_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/create_record.py"
  output_path = "${path.module}/create_record.zip"
}



resource "aws_lambda_function" "create_record_lambda" {
  filename         = data.archive_file.create_record_lambda_zip.output_path
  function_name    = "create_record_lambda"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "create_record.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.create_record_lambda_zip.output_base64sha256
  tags             = var.common_tags
  environment {
    variables = {
      HOSTED_ZONE_ID = var.hosted_zone_id,
      DYNAMODB_TABLE = aws_dynamodb_table.dns_records.name
    }
  }
}



###Delete Record Lambda

data "archive_file" "delete_expired_records_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/delete_expired.py"
  output_path = "${path.module}/delete_expired.zip"
}



resource "aws_lambda_function" "delete_expired_records_lambda" {
  filename         = data.archive_file.delete_expired_records_lambda_zip.output_path
  function_name    = "delete_expired_records"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "delete_expired.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.delete_expired_records_lambda_zip.output_base64sha256
  tags             = var.common_tags
  environment {
    variables = {
      HOSTED_ZONE_ID = var.hosted_zone_id,
      DYNAMODB_TABLE = aws_dynamodb_table.dns_records.name
    }
  }
}

###Report Record Lambda


data "archive_file" "records_report_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/generate_report.py"
  output_path = "${path.module}/generate_report.zip"
}



resource "aws_lambda_function" "records_report_lambda" {
  filename         = data.archive_file.records_report_lambda_zip.output_path
  function_name    = "generate_flashpoint_records_report"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "generate_report.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.records_report_lambda_zip.output_base64sha256
  tags             = var.common_tags
  environment {
    variables = {
      HOSTED_ZONE_ID = var.hosted_zone_id,
      DYNAMODB_TABLE = aws_dynamodb_table.dns_records.name
    }
  }
}


###Lambda Execution Role

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"
  tags = var.common_tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_execution_policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
      },
      {
        Action = [
          "route53:GetHostedZone",
          "route53:ListHostedZones"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.dns_records.arn
      },
      {
        Action = [
          "logs:*"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ],
  })
}

